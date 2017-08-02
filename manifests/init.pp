#
# Copyright (c) IN2P3 Computing Centre, IN2P3, CNRS
#
# Contributor(s) : Remi Ferrand <remi.ferrand_at_cc(dot)in2p3(dot)fr>
#

# == Define: etc_services
#
# Manage a /etc/services entry uniquely identified by its name and protocol.
#
# === Parameters
#
# [*port*]
#   /etc/services entry port. Required.
# [*comment]
#   /etc/services entry comment. Defaults to ''.
# [*aliases*]
#   /etc/services entry aliases specified as an array. Defaults to [].
# [*ensure*]
#   Should /etc/services entry be present or absent. Defaults to present.
#
define etc_services (
  $port,
  $comment = '',
  $aliases = [],
  $ensure = 'present'
)
{
  validate_re($name, '^[-\w]+/(tcp|udp)$')
  validate_re($ensure, '^(absent|present)$')
  validate_re($port, '^\d+$')
  validate_array($aliases)
  validate_string($comment)

  $primary_keys = split($name, '/')
  $service_name = $primary_keys[0]
  $protocol = $primary_keys[1]

  if ($ensure == 'present') {
    $augeas_alias_operations = prefix($aliases, 'set $node/alias[last()+1] ')

    $augeas_pre_alias_operations = [
      "defnode node service-name[.='${service_name}'][protocol = '${protocol}'] ${service_name}",
      "set \$node/port ${port}",
      "set \$node/protocol ${protocol}",
      'remove $node/alias',
      'remove $node/#comment'
    ]

    if empty($comment) {
      $augeas_post_alias_operations = []
    } else {
      $augeas_post_alias_operations = [
        "set \$node/#comment '${comment}'"
      ]
    }

    $augeas_operations = flatten([
      $augeas_pre_alias_operations,
      $augeas_alias_operations,
      $augeas_post_alias_operations
    ])
  }
  else {
    $augeas_operations = [
      "remove service-name[.='${service_name}'][protocol = '${protocol}'] ${service_name}"
    ]
  }

  augeas { "${service_name}_${protocol}":
    incl    => '/etc/services',
    lens    => 'Services.lns',
    changes => $augeas_operations
  }
}

# vim: tabstop=2 shiftwidth=2 softtabstop=2
