#!/usr/bin/env python
# coding: utf-8

from ansible.module_utils.basic import AnsibleModule

ANSIBLE_METADATA = {'metadata_version': '0.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMETATION = '''
---
module: wp_theme
short_description: manage wordpress theme module.
description: manage wordpress theme module.
author: segayuu
option:
	- option-name: name
	  required: True
	  type: str
	- option-name: state
	  default: present
	  choices:
	  	  - present
	  	  - latest
	  	  - deleted
'''

module = AnsibleModule(
	argument_spec=dict(
		#↓本当はこれだと単独か複数かを設定できない、がwordpress側の仕様がいまいちはっきりしきれない・・・
		name=dict(required=True, type='str'), 
		state=dict(default='present', choices=['present', 'latest', 'deleted'])
	),
)

def theme_is_installed(theme):
	rc = module.run_command("wp theme is_install %s" % theme)[0]
	return rc == 0

def theme_is_activate(theme):
	rc, stdout, stderr = module.run_command('wp theme list --format=csv --fields=name,status', check_rc=True)
	#TODO: check active theme, changed管理に必須(wp theme listで表示する(json|csv|yaml)を弄る必要がある！)
	return True

def check_theme_slug(slug):
	#TODO: 実装
	pass

def theme_is_updatable(slug):
	#TODO: 実装
	return True

name = module.params['name']
state = module.params['state']

if state == 'deleted':
	if module.check_mode or not theme_is_installed(name):
		module.exit_json(changed=False)
	stderr = module.run_command("wp theme delete %s" % name, check_rc=True)[2]
	if stderr not '':
		module.warn(stderr)
	module.exit_json(changed=True)

if state != 'present' and state != 'latest':
	module.fail_json(msg='intarnal error: invalid state.')

if module.check_mode:
	module.exit_json(changed=False)

run_install_flag = not theme_is_installed(name)
if run_install_flag:
	stderr = module.run_command("wp theme install %s" % name, check_rc=True)[2]
	if stderr not '':
		module.warn(stderr)

run_activate_flag = run_install_flag or (not theme_is_activate())
if run_activate_flag:
	stderr = module.run_command("wp theme activate %s" % name, check_rc=True)[2]
	if stderr not '':
		module.warn(stderr)

changed_flag = run_install_flag or run_activate_flug

if state == 'latest':
	run_update_flag = theme_is_updatable(theme)
	if run_update_flag:
		stderr = module.run_command("wp theme update %s" % name, check_rc=True)[2]
		if stderr not '':
			module.warn(stderr)
	changed_flag = changed_flag or run_update_flag

module.exit_json(changed=changed_flag)