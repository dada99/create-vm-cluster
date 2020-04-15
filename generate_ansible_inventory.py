#! /usr/bin/python
from jinja2 import Template,Environment, FileSystemLoader
import os,sys
import ipaddress
from pathlib import Path
PROJECT_PATH='{}/projects/{}/'
FIRST_IP = u'192.168.122.100'
FIRST_IP_ADDR = ipaddress.IPv4Address(FIRST_IP)
project_type = sys.argv[1] if len(sys.argv) > 1 else "k8s-1m-2w" # 
print('Using {} type to generate.'.format(project_type))
project_name = input("Give your project a name? ")

try:
  my_path = Path(PROJECT_PATH.format(os.path.dirname(os.path.abspath(__file__)),project_name)) #Create Path Object with project name
  while(my_path.exists()): 
    project_name = input("Your project is exist,plase give another name: ")
    my_path = Path(PROJECT_PATH.format(os.path.dirname(os.path.abspath(__file__)),project_name))
  my_path.mkdir()  
except:
  pass
group_count = input("How many groups to create this time? ")
#print(os.path.dirname(__file__)) # using python python_file_name will set os.path.dirname(__file__) to empty
template_path = '{}/templates/{}'.format(os.path.dirname(os.path.abspath(__file__)),project_type)
loader = FileSystemLoader(template_path)
env = Environment(loader=loader)

k8s_group_template = env.get_template('k8s-1m-2w.j2')
#f1 = open(my_path+'/inventory','w')
f1 = my_path / 'inventory'
# for i in range(int(group_count)):
#     msg = k8s_group_template.render(groupnum=i,groupip=(FIRST_IP_ADDR+i*3),project_n=project_name) # Output for Ansible inventory file
#     print(msg)
#     with f1.open('w') as f:
#         f.write(msg)
with f1.open('w') as f:
    for i in range(int(group_count)):
        msg = k8s_group_template.render(groupnum=i,groupip=(FIRST_IP_ADDR+i*3),project_n=project_name) # Output for Ansible inventory file
        print(msg)
        f.write(msg)
        f.write('\n')
    inventory_all_vars_template = env.get_template('k8s-inventory-all-vars.j2')
    inventory_all_vars = inventory_all_vars_template.render() # Append inventory will all_vars section
    print(inventory_all_vars)
    f.write(inventory_all_vars)
        
f2 = my_path / 'hosts'
k8s_cluster_hosts_template = env.get_template('k8s-1m-2w-hosts.j2')
# print('\n')
# for i in range(int(group_count)):
#     msg = k8s_cluster_hosts_template.render(groupip=(FIRST_IP_ADDR+i*3),groupnum=i,project_n=project_name) # Output for /etc/hosts
#     print(msg)
#     with f2.open('w') as f:
#         f.write(msg)
with f2.open('w') as f:
    for i in range(int(group_count)):
        msg = k8s_cluster_hosts_template.render(groupip=(FIRST_IP_ADDR+i*3),groupnum=i,project_n=project_name) # Output for /etc/hosts
        print(msg)
        f.write(msg)
        f.write('\n')

#Change template path for start and shutdown scripts
template_path = '{}/templates/'.format(os.path.dirname(os.path.abspath(__file__)))
loader = FileSystemLoader(template_path)
env = Environment(loader=loader)
#Generate startup script
startup_cluster_script = my_path / 'startup-cluster.sh'
startup_cluster_template = env.get_template('startup-cluster.j2')
with startup_cluster_script.open('w') as f:
    msg = startup_cluster_template.render(project_n=project_name) # startup-cluster.sh
    f.write(msg)
#Generate startup script
shutdown_cluster_script = my_path / 'shutdown-cluster.sh'
shutdown_cluster_template = env.get_template('shutdown-cluster.j2')
with shutdown_cluster_script.open('w') as f:
    msg = shutdown_cluster_template.render(project_n=project_name) # shutdown-cluster.sh
    f.write(msg)    
    