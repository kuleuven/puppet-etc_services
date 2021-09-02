#
# Copyright (c) IN2P3 Computing Centre, IN2P3, CNRS
#
# Contributor(s) : Remi Ferrand <remi.ferrand_at_cc(dot)in2p3(dot)fr>
#                  Phil DeMonaco <phil_at_demona(dot)co>
#
# @summary Manage a /etc/services entry uniquely identified by its name and protocol.
#
# @param service_name
#   The name of the service in /etc/services. This is a namevar...
#   Note that it should comply with the syntax laid out in 
#   [RFC 6335 Section 5.1](https://tools.ietf.org/html/rfc6335#section-5.1)
#
# @param enforce_syntax
#   When set to true the syntax rules from RFC 6335 are enforced.
#
# @param protocols
#   A hash mapping one or more protocols to their associated ports. This is
#   mandatory.
#
# @param comment
#   An optional comment to be appended to the end of each port/protocol
#   specific line in /etc/services.
#
# @param aliases
#   An optional array of aliases which will be included for each port/protocol
#   combination in /etc/services.
#
# @param ensure
#   Should the corresponding /etc/services entry/entries be present or absent?
#
define etc_services (
  Etc_services::Protocols $protocols,
  String $service_name               = $name,
  Boolean $enforce_syntax            = true,
  Enum['absent','present'] $ensure   = 'present',
  String $comment                    = '',
  Array[String] $aliases             = [],
)
{
  # Validate the name per RFC 6335 section 5.1
  # 1-15 characters
  # Begins and ends with [A-Za-z0-9]
  # Includes only [A-Za-z0-9-]
  # No consecutive '-'
  if $enforce_syntax {
    unless($service_name =~ Etc_services::ServiceName) {
      fail("etc_service: Invalid service name '${service_name}'")
    }
    $aliases.each | $alias | {
      unless($alias =~ Etc_services::ServiceName) {
        fail("etc_services: Invalid service alias '${alias}'")
      }
    }
  }

  # For each port/protocol combination
  $protocols.each | $protocol, $port | {
    if ($ensure == 'present') {
      $entry_prefix = "${service_name} ${port}/${protocol}"

      unless(empty($comment)) {
        $entry_comment = "# ${comment}"
      } else {
        $entry_comment = undef
      }


      unless(empty($aliases)) {
        $entry_aliases = join($aliases, ' ')
      } else {
        $entry_aliases = undef
      }

      if $entry_aliases and $entry_comment {
        $entry_line = "${entry_prefix} ${entry_aliases} ${entry_comment}"
      } elsif $entry_aliases {
        $entry_line = "${entry_prefix} ${entry_aliases}"
      } elsif $entry_comment {
        $entry_line = "${entry_prefix} ${entry_comment}"
      } else {
        $entry_line = $entry_prefix
      }

      file_line { "${service_name}_${protocol}":
        ensure => present,
        path   => '/etc/services',
        line   => $entry_line,
        match  => "^${service_name}\\s+\\d+/${protocol}",
      }
    }
    else {
      file_line { "${service_name}_${protocol}":
        ensure            => absent,
        path              => '/etc/services',
        match             => "^${service_name}\\s+\\d+/${protocol}",
        match_for_absence => true,
      }
    }
  }
}
