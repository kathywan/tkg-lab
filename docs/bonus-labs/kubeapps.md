# Install Kubeapps

### Set environment variables
The following section should be added to or exist in your local params.yaml file:

```bash
kubeapps:
  kubeapps-cn: kubeapps.<shared-cluster domain name>
```

### Change to Shared Services Cluster
Harbor Registry should be installed in the shared services cluster, as it is going to be available to all users.  We need to ensure we are in the correct context before proceeding.

```bash
CLUSTER_NAME=$(yq r $PARAMS_YAML shared-services-cluster.name)
kubectl config use-context $CLUSTER_NAME-admin@$CLUSTER_NAME
```

### Prepare Manifests
Prepare the YAML manifests for the related Harbor K8S objects.  Manifest will be output into `kubeapps/generated/` in case you want to inspect.
```bash
./kubeapps/00-generate_yaml.sh $(yq r $PARAMS_YAML shared-services-cluster.name)
```

### Create Create Kubeapps namespace and certs
Create the Harbor namespace and certificate.  Wait for the certificate to be ready.
```bash
kubectl apply -f generated/$CLUSTER_NAME/kubeapps/01-namespace.yaml
kubectl apply -f generated/$CLUSTER_NAME/kubeapps/02-certs.yaml  
watch kubectl get certificate -n kubeapps
```

### Add helm repo and install kubeapps
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install kubeapps bitnami/kubeapps -f generated/$CLUSTER_NAME/kubeapps/kubeapps-values.yaml --namespace kubeapps
```

## Validation Step
1. All kubeapps pods are in a running state:
```bash
kubectl get po -n kubeapps
```
2. Create serviceaccount and add rolebinding to grand access. More ways to have granular RBAC is documented [here](https://github.com/kubeapps/kubeapps/blob/master/docs/user/access-control.md). For simplicity, we will grant a service account full access:
```bash
kubectl create sa kubeapps-operator
kubectl create clusterrolebinding kubeapps-operator --clusterrole=cluster-admin --serviceaccount=default:kubeapps-operator
```
3. Retrieve API token for this service account
```bash
kubectl get secret $(k get sa kubeapps-operator -o jsonpath='{range .secrets[*]}{.name}{"\n"}{end}' | grep kubeapps-operator-token) -o jsonpath='{.data.token}' -o go-template='{{.data.token | base64decode}}' && echo
```
4. Open a browser and navigate to https://<$KUBEAPPS_CN> and log in with the token retrieved above
```bash
open https://$(yq r $PARAMS_YAML kubeapps.kubeapps-cn)
```

Now you can use Kubeapps to install and manage applications from catalog!