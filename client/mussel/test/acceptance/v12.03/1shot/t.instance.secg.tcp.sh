#!/bin/bash
#
# requires:
#  bash
#  cat, ssh-keygen, ping, rm
#

## include files

. ${BASH_SOURCE[0]%/*}/helper_shunit2.sh
. ${BASH_SOURCE[0]%/*}/helper_instance.sh

## variables

## functions

function render_secg_rule() {
  cat <<-EOS
	icmp:-1,-1,ip4:0.0.0.0/0
	tcp:22,22,ip4:0.0.0.0/0
	EOS
}

function after_create_instance() {
  instance_ipaddr=$(run_cmd instance show ${instance_uuid} | hash_value address)
  wait_for_network_to_be_ready ${instance_ipaddr}
}

### step

function test_drop_tcp22() {
  cat <<-EOS > ${rule_path}
	icmp:-1,-1,ip4:0.0.0.0/0
	EOS
  run_cmd security_group update ${security_group_uuid}

  wait_for_sshd_not_to_be_ready ${instance_ipaddr}
  assertEquals $? 0
}

function test_accept_tcp22() {
  render_secg_rule > ${rule_path}
  run_cmd security_group update ${security_group_uuid}

  wait_for_sshd_to_be_ready ${instance_ipaddr}
  assertEquals $? 0
}

## shunit2

. ${shunit2_file}
