{% set opt_path = '/opt' %}
{% set projects = salt['file.find'](opt_path, type='d', maxdepth=1) | reject('match', opt_path) | list %}

{% for project in projects %}
{% set project_name = project.split('/')[-1] %}
{% if salt['file.file_exists'](project ~ '/salt/init.sls') %}
include:
  - {{ project_name }}.init
{% endif %}
{% endfor %}
