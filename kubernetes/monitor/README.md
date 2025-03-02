# HOW TO MONITOR THE CLUSTER:
- Install Helm
```shell
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

- Set up monitor
```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f prometheus-values.yaml

kubectl get all -n monitoring

# kubectl apply -f mysql-deployment.yaml
# kubectl apply -f monitoring-config.yaml

http://localhost:30001 # or http://127.0.0.1:30001, or http://<ExternalPort>:30001
  # Login with: admin/admin
  # Import Grafana Dashboard:
  #   Click + -> Import
  #   Enter dashboard ID:
  #     Kubernetes Cluster Monitoring (ID: 3119)
  #     Node Exporter Full (ID: 1860)
  #     Kubernetes/Prometheus Cluster Monitoring (ID: 8588)
  #     # 7362 (MariaDB Overview)
  #   Select Prometheus as data source

# kubectl delete -f monitoring-config.yaml
# kubectl delete -f mysql-deployment.yaml
```