# Experimental role for Grafana

## Usage

Create a host file and a playbook with the following content:

```
grafana:
  hosts:
    ip-172-30-0-48.eu-west-1.compute.internal:
```

Run it with:

```
ansible-playbook -i hosts.yml <playbook file>
```


## Credits
This has been adapted from:
https://medium.com/@nanditasahu031/ansible-roles-for-prometheus-grafana-and-nginx-reverse-proxy-part-2-4660030be32f

