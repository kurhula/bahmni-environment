class postgresql {
	package { "postgresql92-libs" : ensure => installed}
	package { "postgresql92-server" : ensure => installed, require => Package["postgresql92-libs"]}
	package { "postgresql92" : ensure => installed, require => Package["postgresql92-server"]}

  $postgresServiceName = "postgresql-9.2"
  $postgresDataFolder = "/var/lib/pgsql/9.2/data"

	exec { "postgresdb" :
		command => "service ${postgresServiceName} initdb",
		path => "${os_path}",
		require => Package["postgresql92"]
	}

	exec { "chkconfig-postgres-server" :
		command => "chkconfig ${postgresServiceName} on",
		path => "${os_path}",
		require => Exec["postgresdb"]
	}

  service {"${postgresServiceName}" :
      ensure      => "running",
      enable      => true,
      require     => Exec["chkconfig-postgres-server"]
  }

  exec{ "backup_postgresql_conf":
      cwd         => "${postgresDataFolder}",
      command     => "mv postgresql.conf postgresql.conf.backup",
  		path        => "${os_path}",
      user        => "${postgresUser}",
      onlyif      => "test -f postgresql.conf",
      require     => Exec["chkconfig-postgres-server"],
  }

  exec{ "backup_pg_hba_conf":
      cwd         => "${postgresDataFolder}",
      command     => "mv pg_hba.conf pg_hba.conf.backup",
  		path        => "${os_path}",
      user        => "${postgresUser}",
      onlyif      => "test -f pg_hba.conf",
      require     => Exec["chkconfig-postgres-server"],
  }
	
	case $postgresMachine {
      master:{
          file {"${postgresDataFolder}/pg_hba.conf":
              content     => template("postgresql/master_pg_hba.erb"),
              owner       => "${postgresUser}",
              group       => "${postgresUser}",
              mode        => 600,
              require     => Exec["backup_postgresql_conf", "backup_pg_hba_conf"],
              notify       => Service["${postgresServiceName}"],
          }

          file {"${postgresDataFolder}/postgresql.conf":
              content     => template("postgresql/master_postgresql.erb"),
              owner       => "${postgresUser}",
              group       => "${postgresUser}",
              mode        => 600,
              require     => Exec["backup_postgresql_conf", "backup_pg_hba_conf"],
              notify       => Service["${postgresServiceName}"],
          }
          
          if $postgresFirstTimeSetup == true {            
            exec { "start_pg_backup_for_replication":
                command     => "psql -c \"SELECT pg_start_backup('replbackup');\"",
            		path        =>  "${os_path}",
                user        => "${postgresUser}",
                require     => [File["${postgresDataFolder}/pg_hba.conf", "${postgresDataFolder}/postgresql.conf"], Service["${postgresServiceName}"]],
            }

            exec { "tar_pg_data_folder":
                command     => "tar cfP /tmp/pg_master_db_file_backup.tar ${postgresDataFolder} --exclude pg_xlog/* --exclude *.conf --exclude postmaster.pid --exclude *.conf.backup",
            		path        =>  "${os_path}",
                user        => "${postgresUser}",
                require     => Exec["start_pg_backup_for_replication"],
            }

            exec { "stop_pg_backup_for_replication":
                command     => "psql -c \"SELECT pg_stop_backup();\"",
            		path        =>  "${os_path}",
                user        => "${postgresUser}",
                require     => Exec["tar_pg_data_folder"],
            }            
          }
      }

      slave:{
          if $postgresFirstTimeSetup == true {            
              exec { "backup_pg_data_folder":
                  command     => "mv ${postgresDataFolder} ${postgresDataFolder}.old",
              		path        =>  "${os_path}",
                  user        => "${postgresUser}",
                  onlyif      => "test -d ${postgresDataFolder}",
                  require     => Exec["backup_postgresql_conf", "backup_pg_hba_conf"],
              }

              exec { "untar_pg_data_folder":
                  command     => "tar xvfP ${postgresMasterDbFileBackup}",
              		path        =>  "${os_path}",
                  user        => "${postgresUser}",
                  require     => Exec["backup_pg_data_folder"],
              }
              
              $pgInitialSetup = Exec["untar_pg_data_folder"]
          } else {            
              $pgInitialSetup = Exec["backup_postgresql_conf", "backup_pg_hba_conf"]
          }

          file {"${postgresDataFolder}/pg_hba.conf":
              content     => template("postgresql/slave_pg_hba.erb"),
              owner       => "${postgresUser}",
              group       => "${postgresUser}",
              mode        => 600,
              require     => $pgInitialSetup,
              notify       => Service["${postgresServiceName}"],
          }

          file {"${postgresDataFolder}/postgresql.conf":
              content     => template("postgresql/slave_postgresql.erb"),
              owner       => "${postgresUser}",
              group       => "${postgresUser}",
              mode        => 600,
              require     => $pgInitialSetup,
              notify       => Service["${postgresServiceName}"],
          }
          
          file {"${postgresDataFolder}/recovery.conf":
              content     => template("postgresql/slave_recovery.erb"),
              owner       => "${postgresUser}",
              group       => "${postgresUser}",
              mode        => 600,
              require     => $pgInitialSetup,
              notify       => Service["${postgresServiceName}"],
          }
      }
  }
}