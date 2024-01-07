This directory contains Helm charts that can be used to install secure-ai-tools.  There might be a parent Helm chart in the future, but for now there are just the individual charts.  They all need to be installed and should work without any changes if your cluster allows all the pods to run as root.  There also needs to be a default storage provisioner available.  An ingress can be set for the secure-ai-tools-web chart if wanted.  I have it setup to do so with a let's encrypt certificate manager.  These are new charts so you might run into problems with installs that are different from the default.

Most charts can run as non-root but the storage needs to be setup with the right permissions.  For the vector-db chart you will probably need to create a new image for chroma that set the permissions for the /chroma directory appropriately.  For the inference image that uses the ollama image I had to setup a mount at "/.ollama" rather than the "/root/.ollama" that is used when running as root.

To install to a kubernetes cluster you can use the following commands.

```
mkdir -p $HOME/src && cd $HOME/src
git clone https://github.com/pj411/SecureAI-Tools.git
cd SecureAI-Tools/k8s/secure-ai-tools/charts
NAMESPACE=secure-ai-tools
CHARTS="secure-ai-tools-db \
        secure-ai-tools-inference \
        secure-ai-tools-vector-db \
        secure-ai-tools-message-broker \
        secure-ai-tools-task-master \
        secure-ai-tools-web"
cd secure-ai-tools/charts
for CHART in $CHARTS
do
  helm -n $NAMESPACE upgrade --install $CHART ./$CHART --create-namespace
done
# after the pods are running you should be able to run the following commands
# and connect to the website with a port forward to http://localhost:28669
export POD_NAME=$(kubectl get pods --namespace secure-ai-tools -l "app.kubernetes.io/name=secure-ai-tools-web,app.kubernetes.io/instance=secure-ai-tools-web" -o jsonpath="{.items[0].metadata.name}")
export CONTAINER_PORT=$(kubectl get pod --namespace secure-ai-tools $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
kubectl --namespace secure-ai-tools port-forward $POD_NAME 28669:$CONTAINER_PORT
```
