# Solr AWS autoscaling experiments

```bash
cat << EOF > vars.auto.tfvars
external_ip = "$(curl -s https://ifconfig.me/ip)"
EOF
tf init
tf apply
```