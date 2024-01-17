# azure-virtual-wan-calico-networking

## Deploy 

```
terraform init
terraform apply --auto-approve
```

Currently, the process of creating BGP connections will encounter a failure because the APIs of the azapi provider are not waiting for the Virtual Hub's routing status to be fully provisioned before they report success. If you experience this failure, a simple workaround is to run terraform apply once more. This should help complete the process successfully.

## Validate

```
kubectl -n calico-system exec -t $(kubectl -n calico-system get po -l k8s-app=calico-node -ojsonpath='{.items[0].metadata.name}') -- birdcl -s /var/run/calico/bird.ctl -r show proto all
kubectl -n calico-system exec -t $(kubectl -n calico-system get po -l k8s-app=calico-node -ojsonpath='{.items[1].metadata.name}') -- birdcl -s /var/run/calico/bird.ctl -r show proto all
```

```
RT=$(az network vhub route-table show --name defaultRouteTable --vhub-name demo-vwan-vhub --resource-group demo-vwan --query id -o tsv)
az network vhub get-effective-routes --resource-type RouteTable -g demo-vwan -n demo-vwan-vhub --resource-id $RT
```

## Cleanup

```
terraform destroy --auto-approve
```

or

```
az group delete --resource-group <RESOURCE GROUP> --no-wait
```

## Reference

Microsoft Build 2023 - [You really can manage ALL Microsoft Azure services and features with Terraform](https://www.youtube.com/watch?v=CTFyjN7zvHg)
