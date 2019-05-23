#!/usr/bin/env bash

az vm create \
  --resource-group "$(whoami)" \
  --name "$(whoami)-metal3-centos-0" \
  --image "OpenLogic:CentOS:7.6:latest" \
  --admin-username "$(whoami)" \
  --size "Standard_D32s_v3" \
  --os-disk-size-gb "128" \
  --ssh-key-value "@${HOME}/.ssh/id_rsa.pub"
