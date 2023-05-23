# bootcamp-terraform

Confluent Bootcamp conform terraform scripts and configuration file.

## preparation

- (optional) create a Python virtual environment
- `pip install -r requirements.txt` 

## convert-to-host.py

Transforms the output of `terraform output -json` into a Ansible hosts.yml used by cp-ansible.

```
usage: convert-to-host.py [-h] [--template TEMPLATE] input keypair

Reads a JSON output from terraform and converts it into an Ansible inventory/

positional arguments:
  input                JSON input file to read
  keypair              Name of the key pair to use for AWS instances

optional arguments:
  -h, --help           show this help message and exit
  --template TEMPLATE  Inventory template (default = hosts.j2)
```

Sample usage: `python3 convert-to-host.py my.json my_keypair --template hosts-kerberos.j2`

## stx_instances.py

Starts and stops ec2 instances in a proper order. Uses information from a terraform state file. Expects AWS credentials in default profile or environment

```
usage: stx-instances.py [-h] [--wait-time WAIT_TIME] [--dry-run] [--no-dry-run] [--state-file STATE_FILE] operation

Start or stop a set of EC2 instances in the appropriate order for a Kafka Cluster

positional arguments:
  operation             Start or stop instances

optional arguments:
  -h, --help            show this help message and exit
  --wait-time WAIT_TIME
                        Duration to wait in seconds between sets of machines when starting/stopping
  --dry-run             Perform a dry run. Default setting
  --no-dry-run          Don't perform a dry run
  --state-file STATE_FILE
                        The location of your terraform state file in which the instances are described
```

Sample usage: `python3 stx-instances.py start --no-dry-run`

## Install Ansible on the jumphost

Install Ansible on the jumphost according to the website. Then, install these collections:

```bash
ansible-galaxy collection install confluent.platform
ansible-galaxy collection install ansible.posix
ansible-galaxy collection install community.general
```

create a file `~/.ansible.cfg` with this content:

```
[defaults]
host_key_checking = False
hash_behaviour = merge
```

## Install Confluent Platform via Ansible

Copy the file `hosts.yml` to the jumphost and run it there:

```
ansible-playbook -i hosts.yml confluent.platform.all
```

## Enable SSL, SASL and SCRAM
In folder `ssl`. generate an SSL CA and add it to `kafka-truststore.jks`. Generate for each host a file `<internal-fqdn>.jks` in the same folder.

Add the following to the generated `hosts.yml` file:

```
all:
  vars:
    ansible_connection: ssh
    ansible_user: ubuntu
    ansible_become: true
    jmxexporter_enabled: true
    ssl_enabled: true
    ssl_provided_keystore_and_truststore: true
    regenerate_keystore_and_truststore: true
    #ssl_mutual_auth_enabled: true
    ssl_keystore_filepath: "/home/ubuntu/ssl/{{inventory_hostname}}-keystore.jks"
    ssl_keystore_key_password: changeme
    ssl_keystore_store_password: changeme
    ssl_truststore_filepath: "/home/ubuntu/ssl/kafka-truststore.jks"
    ssl_truststore_password: changeme
    ssl_truststore_ca_cert_alias: root-ca
    kafka_broker_custom_properties:
      super.users: "User:alice;User:kafka;User:schema-registry;User:ksqldb;User:kafka_rest;User:control-center;User:kafka-connect;User:kafka_connect_replicator"
      authorizer.class.name: kafka.security.authorizer.AclAuthorizer
      auto.create.topics.enable: false
    sasl_protocol: scram
    sasl_scram_users:
      admin:
        principal: 'kafka'
        password: 'admin-secret'
      schema_registry:
        principal: 'schema-registry'
        password: 'schema_registry-secret'
      kafka_connect:
        principal: 'kafka-connect'
        password: 'kafka_connect-secret'
      ksql:
        principal: 'ksqldb'
        password: 'ksql-secret'
      kafka_rest:
        principal: 'kafka_rest'
        password: 'kafka_rest-secret'
      control_center:
        principal: 'control-center'
        password: 'control_center-secret'
      kafka_connect_replicator:
        principal: 'kafka_connect_replicator'
        password: 'kafka_connect_replicator-secret
      alice:
        principal: 'alice'
        password: 'alice-secret'
```

In this example, user `alice` is superuser as well as all internal service users. For production systems, the latter need to be narrowed down.

## Install Prometheus and Grafana

Install prometheus collection:

```bash
ansible-galaxy collection install prometheus.prometheus
ansible-galaxy collection install community.grafana
```

Copy the file `playbook-monitoring.yml` to the jumphost, then execute it there:

```bash
ansible-playbook -i hosts.yml playbook-monitoring.yml
```
