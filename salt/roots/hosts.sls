# ./salt/roots/hosts.sls
/etc/hosts:
  file.managed:
    - source: salt://files/hosts
    - user: root
    - group: root
    - mode: 644
