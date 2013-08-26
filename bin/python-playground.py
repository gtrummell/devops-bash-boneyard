#!/usr/bin/env python

import chef
import time
import dns.resolver
import paramiko
import threading

# Set variables here.  These will be replaced by test magic.

cmd = "sudo chef-client"
username = "username"
key_filename = "/path/to/ssh.key"

chef_config = chef.autoconfigure()

outlock = threading.Lock()


def dnsquery(host):
    for rdata in dns.resolver.query(host, 'CNAME'):
        return rdata.to_text().split('.')[0]


def set_secret_uri(host):
    node_id = dnsquery(host)
    node = chef.Node(node_id, api=chef_config)
    node['secret_uri'] = "https://%s.secreturi.com" % (time.strftime("%Y%M%dT%H%M%S"))
    node.save()
    print node['secret_uri']


def remote(host):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, username=username, key_filename=key_filename)
    stdin, stdout, stderr = ssh.exec_command(cmd)
    stdin.write('xy\n')
    stdin.flush()

    with outlock:
        print stdout.readlines()


def main():
    hosts = ['host1', 'host2', 'host3', ]
    threads = []
    for h in hosts:
        set_secret_uri(h)
        t = threading.Thread(target=remote, args=(h,))
        t.start()
        threads.append(t)
    for t in threads:
        t.join()


main()
