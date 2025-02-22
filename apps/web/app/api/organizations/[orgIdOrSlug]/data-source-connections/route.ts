import { NextRequest, NextResponse } from "next/server";

import { isAuthenticated } from "lib/api/core/auth";
import { OrgMembershipService } from "lib/api/services/org-membership-service";
import { OrganizationService } from "lib/api/services/organization-service";
import { DataSourceConnectionCreateRequest } from "lib/types/api/data-source-connection-create.request";
import { isOAuthDataSource } from "lib/api/core/data-source.utils";

import {
  NextResponseErrors,
  API,
  DataSourceConnectionService,
  DataSourceConnectionCreateInput,
  OAuthService,
} from "@repo/backend";
import {
  DataSourceConnectionResponse,
  Id,
  OrgMembershipStatus,
  isEmpty,
} from "@repo/core";

const orgMembershipService = new OrgMembershipService();
const orgService = new OrganizationService();
const dataSourceConnectionService = new DataSourceConnectionService();
const oauthService = new OAuthService();

export async function GET(
  req: NextRequest,
  { params }: { params: { orgIdOrSlug: string } },
) {
  const [authenticated, authUserId] = await isAuthenticated(req);
  if (!authenticated) {
    return NextResponseErrors.unauthorized();
  }

  if (params.orgIdOrSlug.length < 1) {
    return NextResponseErrors.badRequest();
  }

  const { searchParams } = new URL(req.url);
  const userIdParam = searchParams.get("userId");
  const dataSourcesParam = searchParams.getAll("dataSource");
  if (authUserId?.toString() !== userIdParam) {
    // TODO: In future, allow org admins to call this endpoint
    return NextResponseErrors.forbidden();
  }

  const org = await orgService.get(params.orgIdOrSlug);
  if (!org) {
    return NextResponseErrors.notFound();
  }

  const hasPermissions = await orgMembershipService.isActiveMember(
    authUserId!,
    params.orgIdOrSlug,
  );
  if (!hasPermissions) {
    return NextResponseErrors.forbidden();
  }

  // Get data source connection for userIdParam's membership
  const where = {
    membership: {
      orgId: org.id,
      userId: userIdParam,
      status: OrgMembershipStatus.ACTIVE,
    },
    ...(dataSourcesParam.length > 0 && {
      dataSource: {
        in: dataSourcesParam,
      },
    }),
  };
  const dataSourceConnections = await dataSourceConnectionService.getAll({
    where: where,
    orderBy: API.searchParamsToOrderByInput(searchParams),
    pagination: API.PaginationParams.from(searchParams),
  });
  const count = await dataSourceConnectionService.count(where);

  return NextResponse.json(
    dataSourceConnections.map((dsc) =>
      DataSourceConnectionResponse.fromEntity(dsc),
    ),
    {
      headers: API.createResponseHeaders({
        pagination: {
          totalCount: count,
        },
      }),
    },
  );
}

export async function POST(
  req: NextRequest,
  { params }: { params: { orgIdOrSlug: string } },
) {
  const [authenticated, userId] = await isAuthenticated(req);
  if (!authenticated) {
    return NextResponseErrors.unauthorized();
  }

  if (params.orgIdOrSlug.length < 1) {
    return NextResponseErrors.badRequest();
  }

  const org = await orgService.get(params.orgIdOrSlug);
  if (!org) {
    return NextResponseErrors.notFound();
  }

  const hasPermissions = await orgMembershipService.isActiveMember(
    userId!,
    params.orgIdOrSlug,
  );
  if (!hasPermissions) {
    return NextResponseErrors.forbidden();
  }

  const orgMemberships = await orgMembershipService.getAll({
    userId: userId!.toString(),
    orgId: org.id,
    status: OrgMembershipStatus.ACTIVE,
  });

  if (orgMemberships.length === 0) {
    return NextResponseErrors.forbidden();
  }

  if (orgMemberships.length > 1) {
    throw new Error(
      `found ${orgMemberships.length} active membership for userId=${userId} & orgIdOrSlug=${params.orgIdOrSlug}`,
    );
  }

  const dataSourceConnectionCreateRequest =
    (await req.json()) as DataSourceConnectionCreateRequest;

  const { dataSource, baseUrl, authorizationCode, redirectUri } = dataSourceConnectionCreateRequest;
    
  let input: DataSourceConnectionCreateInput;
  if (isOAuthDataSource(dataSource)) {
    if(isEmpty(authorizationCode) || isEmpty(redirectUri)) {
      return NextResponseErrors.badRequest(
        `authorizationCode and redirectUri are required for ${dataSource}`
      );
    }

    // Exchange authorization code for access token!
    const tokens = await oauthService.getAccessToken({
      dataSource: dataSource,
      authorizationCode: authorizationCode!,
      redirectUri: redirectUri!,
      orgId: Id.from(org.id),
    });

    input = {
      dataSource: dataSource,
      baseUrl: dataSourceConnectionCreateRequest.baseUrl,
      accessToken: tokens.accessToken,
      accessTokenExpiresAt: tokens.accessTokenExpiresAt,
      refreshToken: tokens.refreshToken,
      membershipId: Id.from(orgMemberships[0]!.id),
    };
  } else {
    input = {
      dataSource: dataSource,
      baseUrl: baseUrl,
      accessToken: dataSourceConnectionCreateRequest.accessToken,
      accessTokenExpiresAt:
        dataSourceConnectionCreateRequest.accessTokenExpiresAt,
      membershipId: Id.from(orgMemberships[0]!.id),
    };
  }

  const connection = await dataSourceConnectionService.create(input);

  return NextResponse.json(DataSourceConnectionResponse.fromEntity(connection));
}
