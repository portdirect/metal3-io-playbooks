source ${HOME}/.bash_profile
export ANSIBLE_CALLBACK_PLUGINS="$(python -c 'import os,ara; print(os.path.dirname(ara.__file__))')/plugins/callbacks"
rm -rf ${HOME}/.ara
ansible-playbook ./setup-playbook.yml -i ./inventory.yaml
