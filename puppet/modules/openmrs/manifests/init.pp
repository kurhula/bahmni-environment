class openmrs {
  require bahmni_distro
  require tomcat::clean
  require bahmni_snapshot_migrations

  $log4j_xml_file = "${tomcatInstallationDirectory}/webapps/openmrs/WEB-INF/classes/log4j.xml"
  $openmrs_webapp_location =  "${tomcatInstallationDirectory}/webapps/openmrs"
  $web_xml_file = "${openmrs_webapp_location}/WEB-INF/web.xml"

  exec { "delete_${openmrs_webapp_location}" :
    command     => "rm -rf ${openmrs_webapp_location}",
    path        => "${os_path}",
  }

  file { "/home/${bahmni_user}/.OpenMRS/openmrs-runtime.properties" :
    ensure      => present,
    owner       => "${bahmni_user}",
    group       => "${bahmni_user}",
    mode        => 664,
    content     => template("openmrs/openmrs-runtime.properties"),
    require     => File["/home/${bahmni_user}/.OpenMRS"]
  }

  exec { "latest_openmrs_webapp" :
    command   => "unzip -o -q ${build_output_dir}/${openmrs_distro_file_name_prefix}/${openmrs_war_file_name}.war -d ${openmrs_webapp_location} ${deployment_log_expression}",
    provider  => shell,
    path      => "${os_path}",
    require   => [File["${deployment_log_file}"], Exec["delete_${openmrs_webapp_location}"]],
    user      => "${bahmni_user}"
  }

  file { "/home/${bahmni_user}/.OpenMRS" :
    ensure      => directory,
    owner       => "${bahmni_user}",
    group       => "${bahmni_user}",
    mode        => 666
  }

  file { "${log4j_xml_file}" :
    ensure      => present,
    content     => template("openmrs/log4j.xml.erb"),
    owner       => "${bahmni_user}",
    group       => "${bahmni_user}",
    require     => Exec["latest_openmrs_webapp"],
    mode        => 664,
  }

  file { "${web_xml_file}" :
    ensure      => present,
    content     => template("openmrs/web.xml"),
    owner       => "${bahmni_user}",
    group       => "${bahmni_user}",
    require     => Exec["latest_openmrs_webapp"],
    mode        => 664
  }

  file { "${temp_dir}/openmrs-predeploy.sql" :
    ensure      => present,
    content     => template("openmrs/predeploy.sql"),
    owner       => "${bahmni_user}",
    group       => "${bahmni_user}"
  }

  exec { "openmrs_predeploy" :
    command     => "mysql -uroot -p${mysqlRootPassword} < ${temp_dir}/openmrs-predeploy.sql ${deployment_log_expression}",
    path        => "${os_path}",
    provider    => shell,
    require     => [Exec["openmrs_database"],File["${temp_dir}/openmrs-predeploy.sql"]]
  }

  file { "${temp_dir}/run-liquibase-openmrs.sh" :
    ensure      => present,
    content     => template("openmrs/run-liquibase.sh"),
    owner       => "${bahmni_user}",
    group       => "${bahmni_user}",
    mode        => 554,
    require     => [Class['bahmni_snapshot_migrations'], Exec['run-snapshot-migrations']]
 }

  exec { "openmrs_data" :
    command     => "${temp_dir}/run-liquibase-openmrs.sh  ${deployment_log_expression}",
    path        => "${os_path}",
    provider    => shell,
    timeout     => 0,
    cwd         => "${tomcatInstallationDirectory}/webapps",
    require     => [Exec["openmrs_predeploy"], File["${temp_dir}/run-liquibase-openmrs.sh"], Exec["latest_openmrs_webapp"]]
  }

   exec { "bahmni_java_utils_jars" :
    command => "cp ${build_output_dir}/${openmrs_distro_file_name_prefix}/mail-appender-${bahmni_release_version}.jar ${tomcatInstallationDirectory}/webapps/openmrs/WEB-INF/lib ${deployment_log_expression}",
    user    => "${bahmni_user}",
    require => Exec["latest_openmrs_webapp"],
    path => "${os_path}"
  }

}