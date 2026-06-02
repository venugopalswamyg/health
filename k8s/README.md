This folder contains example commands and manifests to install cert-manager and ingress-nginx in AKS.

Install cert-manager via helm:

```bash
kubectl create namespace cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.15.0 --set installCRDs=true
```

Install ingress-nginx via helm:

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
```

Apply the example ClusterIssuer (Let's Encrypt staging) to request TLS certs for testing:

```bash
kubectl apply -f k8s/cluster-issuer.yaml
```

Notes:
- Replace `your-email@example.com` in `cluster-issuer.yaml` with your email.
- For production, use `https://acme-v02.api.letsencrypt.org/directory` and a `letsencrypt-prod` ClusterIssuer.
