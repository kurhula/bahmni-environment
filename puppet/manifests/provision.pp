import "configurations/node-configuration"
import "configurations/stack-installers-configuration"
import "configurations/stack-runtime-configuration"
import "configurations/deployment-configuration"

stage { 'first_stage' : before => Stage['main'] }

node default {

	class { 'yum_repo': stage => 'first_stage' }
    class { 'selinux': stage => 'first_stage' }
	include host
	include tools
 	include java
	include mysql
	include mysqlserver
	include python_setup_tools
    if ($bahmni_openerp_required == "true") or ($bahmni_openelis_required == "true") {
	    include postgresql
    }
	class { 'users' : userName => "${bahmni_user}", password_hash => "${bahmni_user_password_hash}"}
	include tomcat
	class { 'tomcat_conf': require => Class["tomcat"] }
	include httpd
	class { 'jasperserver': require => Class["tomcat"] }
	if $bahmni_openerp_required == "true" {
	 	include python
		class { 'openerp': require => Class["python", "postgresql"] }
	}
#	include nagios
#	include bahmni_nagios
	include cron_tab
}