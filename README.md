# azure-virtual-wan-calico-networking

## Deploy 

```
terraform init
terraform apply --auto-approve
```

Currently, the process of creating BGP connections will encounter a failure because the APIs of the azapi provider are not waiting for the Virtual Hub's routing status to be fully provisioned before they report success. If you experience this failure, a simple workaround is to run terraform apply once more. This should help complete the process successfully.

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
