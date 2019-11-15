# Deployment of Net-SNMP for Platina Cluster Heads

## Overview

This directory contains an Ansible playbook for deployment of Net-SNMP on a Platina Cluster Head.  Once pulled to a Platina Cluster Head, the same playbook can be used to configure multiple CLuster Heads as long as there connectivity. This playbook also includes a an extension module and MIB for additional stats and metrics not available by default within Net-SNMP.

This playbook can currently be executed by hand, but will eventually be rolled into the PCC orchestration framework.

## Dependencies

Ansible and ansible connectivity among the Cluster Heads on which snmpd is  to be configured.

## Execution

1. Pull this repo from github using the following command: 
1. Update the given `host_vars.yml` with your own host variables(Ex. communityString, managementIP, etc.)  See example below.
1. In the `inventory.ini` file, include all the Cluster Heads on which you want to install the snmpd, so that all  get configured at the same time.  See example below. 
1. Run the Ansible playbook (`snmpd.yml`) using the following command: `ansible-playbook -i ./inventory.ini ./snmpd.yml`, where `snmpd.yml` is the playbook and `./inventory.ini` is an Ansible-format inventory file indicating the Cluster Head(s) you wish Net-SNMP be deployed to.
1. The included `Platina-MIB.txt` file is an SNMP MIB file that may be used with the SNMP client of your choice.


## inventory.ini Input Parameters
The provided playbook makes use of the following variables as its input from the `inventory.ini`:
```
---
192.68.1.49
192.68.1.50

```
* each entry above references the mgmt IP of a Cluster Head you would like NET-SNMP installed

## host_vars Input Parameters
The provided playbook makes use of the following variables as its input from the `host_vars`:

```
---
managementIp: 192.68.1.49
communityString: public
location: SantaClara
email: customer@customer.com
contact: John_Smith
include_nonfree: true

```
* community\_string -- this is the standard SNMPv2 community string
* management\_ip -- this is the IP address of the management interface. This playbook binds the SNMP service to the management interface to reduce attack surface.
* location -- this is the standard SNMP location field
* contact -- this is the standard SNMP contact field
* email -- this is the standard SNMP contact email address field
* include\_nonfree -- some of the components this playbook deploys are in the Debian non-free repository. When set to _true_, this variable causes the playbook to add the non-free repository and install packages from there (primarily third party SNMP MIBs). These MIBs are not required for normal operation.

## Sample SNMP query

```
    snmpbulkwalk -v2c -c public 172.17.2.69 -m PLATINA-MIB .1.3.6.1.4.1.48226
```

Where:
* _public_ is the community name,
* _203.0.113.10_ is the management IP of the cluster heaaad,
* PLATINA-MIB is the module name in the Platina MIB
* _.1.3.6.1.4.1.48226_ is the OID of the Platina OID space

