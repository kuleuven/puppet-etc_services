#
# Copyright (c) IN2P3 Computing Centre, IN2P3, CNRS
#
# Contributor(s) : Remi Ferrand <remi.ferrand_at_cc(dot)in2p3(dot)fr>
#
# @summary Manage a /etc/services entry uniquely identified by its name and protocol.
#
# @param service_name [String]
#   The name of the service in /etc/services. This is a namevar...
#   Note that it must comply with the syntax laid out in 
#   [RFC 6335 Section 5.1](https://tools.ietf.org/html/rfc6335#section-5.1)
#
# @param protocols [Hash[Enum['tcp','udp'],Integer]]
#   A hash mapping one or more protocols to their associated ports. This is
#   mandatory.
#
# @param comment [String]
#   An optional comment to be appended to the end of each port/protocol
#   specific line in /etc/services.
#
# @param aliases [Array[String]]
#   An optional array of aliases which will be included for each port/protocol
#   combination in /etc/services.
#
# @param ensure [Enum['absent','present']]
#   Should the corresponding /etc/services entry/entries be present or absent?
#
define etc_services (
  String  $service_name = $name,
  Enum['absent','present'] $ensure           = 'present',
  String $comment                            = '',
  Array[String] $aliases                     = [],
  Hash[Enum['tcp','udp'],Integer] $protocols = undef,
)
{
  # Validate the name per RFC 6335 section 5.1
  # 1-15 characters
  # Begins and ends with [A-Za-z0-9]
  # Includes only [A-Za-z0-9-]
  # No consecutive '-'
  unless($service_name =~
    /^(?=.{1,15}$)(?=[A-Za-z0-9])(?=[A-Za-z0-9-]*[A-Za-z0-9]$)(?!.*([-])\1)[A-Za-z0-9-]+$/) {
    fail("etc_service: Invalid service name '${service_name}'")
  }
  $aliases.each | $alias | {
    unless($alias =~
      /^(?=.{1,15}$)(?=[A-Za-z0-9])(?=[A-Za-z0-9-]*[A-Za-z0-9]$)(?!.*([-])\1)[A-Za-z0-9-]+$/) {
      fail("etc_services: Invalid service alias '${alias}'")
    }
  }

  # For each port/protocol combination
  $protocols.each | $protocol, $port | {
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
}
