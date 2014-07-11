import "configurations/node-configuration"
import "configurations/stack-installers-configuration"
import "configurations/stack-runtime-configuration"
import "configurations/deployment-configuration"
import "configurations/openmrs-versions-configuration.pp"

node default {
  include bahmni-openmrs
  include bahmni-openerp
  include openelis
  include reference-data
  class { 'implementation-config':
    implementationName => "${implementation}", require => [ Class['bahmni-webapps'], Class['openelis'], Class['bahmni-openerp']],
  }
}