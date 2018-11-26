#
# Copyright (c) IN2P3 Computing Centre, IN2P3, CNRS
#
# Contributor(s) : Remi Ferrand <remi.ferrand_at_cc(dot)in2p3(dot)fr>
#
# == Define: etc_services
#
# @summary Manage a /etc/services entry uniquely identified by its name and protocol.
#
# === Parameters
#
# @param service_name [String]
#   The name of the service in /etc/services. This is a namevar...
#
# @param ports
#   /etc/services entry port. Required.
#
# @param comment
#   /etc/services entry comment. Defaults to ''.
#
# @param aliases
#   /etc/services entry aliases specified as an array. Defaults to [].
#
# @param ensure
#   Should /etc/services entry be present or absent. Defaults to present.
#
define etc_services (
  String $service_name = $name,
  Enum['absent','present'] $ensure = 'present',
  String $comment = '',
  Array[String] $aliases = [],
  Array[Pattern[/^\d+\/(tcp|udp)$/]] $ports = [],
)
{

  $protocol = $primary_keys[1]

  if ($ensure == 'present') {
    $ports.each | $port_tuple | {
      $primary_keys = split($port_tuple, '/')
      $port = $primary_keys[0]
      $protocol = $primary_keys[1]

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
