#
# Copyright (c) IN2P3 Computing Centre, IN2P3, CNRS
#
# Contributor(s) : ccin2p3
#

# == Class etc_services::params
#
# This class is meant to be called from etc_services
# It sets variables according to platform
#
class etc_services::params {
  case $::osfamily {
    'Debian': {
      $package_name = 'etc_services'
      $service_name = 'etc_services'
    }
    'RedHat', 'Amazon': {
      $package_name = 'etc_services'
      $service_name = 'etc_services'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}
