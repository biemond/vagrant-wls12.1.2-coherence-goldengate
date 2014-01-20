node 'oradb'  {

   include oradb_os
   include goldengate_11g
   include oradb_11g
   include oradb_maintenance

}

# operating settings for Database & Middleware
class oradb_os {

  service { iptables:
    enable    => false,
    ensure    => false,
    hasstatus => true,
  }

  group { 'dba' :
    ensure      => present,
  }

  user { 'oracle' :
    ensure      => present,
    gid         => 'dba',  
    groups      => 'dba',
    shell       => '/bin/bash',
    password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home        => "/home/oracle",
    comment     => "This user oracle was created by Puppet",
    require     => Group['dba'],
    managehome  => true,
  }

  user { 'ggate' :
    ensure      => present,
    gid         => 'dba',  
    groups      => 'dba',
    shell       => '/bin/bash',
    password    => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home        => "/home/ggate",
    comment     => "This user ggate was created by Puppet",
    require     => Group['dba'],
    managehome  => true,
  }



  $install = [ 'binutils.x86_64', 'compat-libstdc++-33.x86_64', 'glibc.x86_64','ksh.x86_64','libaio.x86_64',
               'libgcc.x86_64', 'libstdc++.x86_64', 'make.x86_64','compat-libcap1.x86_64', 'gcc.x86_64',
               'gcc-c++.x86_64','glibc-devel.x86_64','libaio-devel.x86_64','libstdc++-devel.x86_64',
               'sysstat.x86_64','unixODBC-devel','glibc.i686','libXext.i686','libXtst.i686']
       

  package { $install:
    ensure  => present,
  }

  class { 'limits':
         config => {
                    '*'       => { 'nofile'  => { soft => '2048'   , hard => '8192',   },},
                    'oracle'  => { 'nofile'  => { soft => '65536'  , hard => '65536',  },
                                    'nproc'  => { soft => '2048'   , hard => '16384',  },
                                    'stack'  => { soft => '10240'  ,},},
                    },
         use_hiera => false,
  }
 
  sysctl { 'kernel.msgmnb':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.msgmax':                 ensure => 'present', permanent => 'yes', value => '65536',}
  sysctl { 'kernel.shmmax':                 ensure => 'present', permanent => 'yes', value => '2588483584',}
  sysctl { 'kernel.shmall':                 ensure => 'present', permanent => 'yes', value => '2097152',}
  sysctl { 'fs.file-max':                   ensure => 'present', permanent => 'yes', value => '6815744',}
  sysctl { 'net.ipv4.tcp_keepalive_time':   ensure => 'present', permanent => 'yes', value => '1800',}
  sysctl { 'net.ipv4.tcp_keepalive_intvl':  ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'net.ipv4.tcp_keepalive_probes': ensure => 'present', permanent => 'yes', value => '5',}
  sysctl { 'net.ipv4.tcp_fin_timeout':      ensure => 'present', permanent => 'yes', value => '30',}
  sysctl { 'kernel.shmmni':                 ensure => 'present', permanent => 'yes', value => '4096', }
  sysctl { 'fs.aio-max-nr':                 ensure => 'present', permanent => 'yes', value => '1048576',}
  sysctl { 'kernel.sem':                    ensure => 'present', permanent => 'yes', value => '250 32000 100 128',}
  sysctl { 'net.ipv4.ip_local_port_range':  ensure => 'present', permanent => 'yes', value => '9000 65500',}
  sysctl { 'net.core.rmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.rmem_max':             ensure => 'present', permanent => 'yes', value => '4194304', }
  sysctl { 'net.core.wmem_default':         ensure => 'present', permanent => 'yes', value => '262144',}
  sysctl { 'net.core.wmem_max':             ensure => 'present', permanent => 'yes', value => '1048576',}

}



class oradb_11g {
  require oradb_os

    oradb::installdb{ '11.2_linux-x64':
            version                => '11.2.0.4',
            file                   => 'p13390677_112040_Linux-x86-64',
            databaseType           => 'SE',
            oracleBase             => hiera('oracle_base_dir'),
            oracleHome             => hiera('oracle_home_dir'),
            userBaseDir            => '/home',
            createUser             => false,
            user                   => hiera('oracle_os_user'),
            group                  => hiera('oracle_os_group'),
            downloadDir            => hiera('oracle_download_dir'),
            remoteFile             => false,
            puppetDownloadMntPoint => hiera('oracle_source'),  
    }

   oradb::net{ 'config net8':
            oracleHome   => hiera('oracle_home_dir'),
            version      => hiera('oracle_version'),
            user         => hiera('oracle_os_user'),
            group        => hiera('oracle_os_group'),
            downloadDir  => hiera('oracle_download_dir'),
            require      => Oradb::Installdb['11.2_linux-x64'],
   }

   oradb::listener{'start listener':
            oracleBase   => hiera('oracle_base_dir'),
            oracleHome   => hiera('oracle_home_dir'),
            user         => hiera('oracle_os_user'),
            group        => hiera('oracle_os_group'),
            action       => 'start',  
            require      => Oradb::Net['config net8'],
   }

   oradb::database{ 'oraDb': 
                    oracleBase              => hiera('oracle_base_dir'),
                    oracleHome              => hiera('oracle_home_dir'),
                    version                 => hiera('oracle_version'),
                    user                    => hiera('oracle_os_user'),
                    group                   => hiera('oracle_os_group'),
                    downloadDir             => hiera('oracle_download_dir'),
                    action                  => 'create',
                    dbName                  => hiera('oracle_database_name'),
                    dbDomain                => hiera('oracle_database_domain_name'),
                    sysPassword             => hiera('oracle_database_sys_password'),
                    systemPassword          => hiera('oracle_database_system_password'),
                    dataFileDestination     => "/oracle/oradata",
                    recoveryAreaDestination => "/oracle/flash_recovery_area",
                    characterSet            => "AL32UTF8",
                    nationalCharacterSet    => "UTF8",
                    initParams              => "open_cursors=1000,processes=600,job_queue_processes=4",
                    sampleSchema            => 'TRUE',
                    memoryPercentage        => "40",
                    memoryTotal             => "800",
                    databaseType            => "MULTIPURPOSE",                         
                    require                 => Oradb::Listener['start listener'],
   }

   oradb::dbactions{ 'start oraDb': 
                   oracleHome              => hiera('oracle_home_dir'),
                   user                    => hiera('oracle_os_user'),
                   group                   => hiera('oracle_os_group'),
                   action                  => 'start',
                   dbName                  => hiera('oracle_database_name'),
                   require                 => Oradb::Database['oraDb'],
   }

   oradb::autostartdatabase{ 'autostart oracle': 
                   oracleHome              => hiera('oracle_home_dir'),
                   user                    => hiera('oracle_os_user'),
                   dbName                  => hiera('oracle_database_name'),
                   require                 => Oradb::Dbactions['start oraDb'],
   }



}

class goldengate_11g {
   require oradb_11g

      $ggateFile       = '121200_fbo_ggs_Linux_x64_shiphome.zip'
      $ggateInstallDir = '121200_fbo_ggs_Linux_x64_shiphome'
      $installDir      = '/installgg'
      $sourceDir       = '/vagrant'
      $softwareDir     = hiera('oracle_source')

      file { $installDir :
        ensure        => directory,
        recurse       => false,
        replace       => false,
        mode          => 0775,
        owner         => hiera('ggate_os_user'),
        group         => hiera('oracle_os_group'),
      }

      file { "${installDir}/${ggateFile}":
        source      => "${softwareDir}/${ggateFile}",
        require     => File[$installDir],
        owner       => hiera('ggate_os_user'),
        group       => hiera('oracle_os_group'),
      }

      exec { "extract 121200_fbo_ggs_Linux_x64_shiphome":
        command     => "unzip -o ${installDir}/${ggateFile} -d ${installDir}/${ggateInstallDir}",
        require     => File["${installDir}/${ggateFile}"],
        creates     => "${installDir}/${ggateInstallDir}/fbo_ggs_Linux_x64_shiphome",
        timeout     => 0,
        path        => "/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin",
        user        => hiera('ggate_os_user'),
        group       => hiera('oracle_os_group'),
      }

      file { "${installDir}/oggcore.rsp":
        source      => "${sourceDir}/oggcore.rsp",
        require     => File[$installDir],
        owner       => hiera('ggate_os_user'),
        group       => hiera('oracle_os_group'),
      }

      file { "/oracle/product" :
        ensure        => directory,
        recurse       => false,
        replace       => false,
        mode          => 0775,
        group         => hiera('oracle_os_group'),
      }
      
      exec { "install oracle goldengate":
          command     => "/bin/sh -c 'unset DISPLAY;${installDir}/${ggateInstallDir}/fbo_ggs_Linux_x64_shiphome/Disk1/runInstaller -silent -waitforcompletion -responseFile ${installDir}/oggcore.rsp'",
          require     => [ File["${installDir}/oggcore.rsp"],
                           File["/oracle/product"],
                           Exec["extract 121200_fbo_ggs_Linux_x64_shiphome"]
                         ],
          creates     => "/oracle/product/12.1.2/ggate",
          timeout     => 0,
          path        => "/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/sbin",
          logoutput   => true,
          user        => hiera('ggate_os_user'),
          group       => hiera('oracle_os_group'),
          returns     => [3,0],
      }

      # cd /oracle/product/12.1.2/ggate
      # . oraenv
      # test
      # ./ggsci
      # info all
      # 

}


class oradb_maintenance {
  require oradb_11g

  case $operatingsystem {
    CentOS, RedHat, OracleLinux, Ubuntu, Debian: { 
      $mtimeParam = "1"
    }
    Solaris: { 
      $mtimeParam = "+1"
    }
  }


  cron { 'oracle_db_opatch' :
    command => "find /oracle/product/11.2/db/cfgtoollogs/opatch -name 'opatch*.log' -mtime ${mtimeParam} -exec rm {} \\; >> /tmp/opatch_db_purge.log 2>&1",
    user    => oracle,
    hour    => 06,
    minute  => 34,
  }
  
  cron { 'oracle_db_lsinv' :
    command => "find /oracle/product/11.2/db/cfgtoollogs/opatch/lsinv -name 'lsinventory*.txt' -mtime ${mtimeParam} -exec rm {} \\; >> /tmp/opatch_lsinv_db_purge.log 2>&1",
    user    => oracle,
    hour    => 06,
    minute  => 32,
  }


}

