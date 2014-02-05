# test
#
# one machine setup with weblogic 12.1.2 with OPatch
# needs jdk7, orawls, orautils, fiddyspence-sysctl, erwbgy-limits puppet modules
#

node 'adminwls.example.com' {
  
  include os, ssh, java
  include orawls::weblogic, orautils
  include domains, nodemanager, startwls, userconfig
  include machines
  #, datasources
  include server_templates
  include cluster
  include coherence
  include pack_domain
  include goldengate_11g


  Class[java] -> Class[orawls::weblogic]
}  

# operating settings for Middleware
# operating settings for Middleware
class os {

  notice "class os ${operatingsystem}"

  $default_params = {}
  $host_instances = hiera('hosts', [])
  create_resources('host',$host_instances, $default_params)

  exec { "create swap file":
    command => "/bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=8192",
    creates => "/var/swap.1",
  }

  exec { "attach swap file":
    command => "/sbin/mkswap /var/swap.1 && /sbin/swapon /var/swap.1",
    require => Exec["create swap file"],
    unless => "/sbin/swapon -s | grep /var/swap.1",
  }

  #add swap file entry to fstab
  exec {"add swapfile entry to fstab":
    command => "/bin/echo >>/etc/fstab /var/swap.1 swap swap defaults 0 0",
    require => Exec["attach swap file"],
    user => root,
    unless => "/bin/grep '^/var/swap.1' /etc/fstab 2>/dev/null",
  }

  service { iptables:
        enable    => false,
        ensure    => false,
        hasstatus => true,
  }

  group { 'dba' :
    ensure => present,
  }

  # http://raftaman.net/?p=1311 for generating password
  # password = oracle
  user { 'oracle' :
    ensure     => present,
    groups     => 'dba',
    shell      => '/bin/bash',
    password   => '$1$DSJ51vh6$4XzzwyIOk6Bi/54kglGk3.',
    home       => "/home/oracle",
    comment    => 'oracle user created by Puppet',
    managehome => true,
    require    => Group['dba'],
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


  $install = [ 'binutils.x86_64','unzip.x86_64']


  package { $install:
    ensure  => present,
  }

  class { 'limits':
    config => {
               '*'       => {  'nofile'  => { soft => '2048'   , hard => '8192',   },},
               'oracle'  => {  'nofile'  => { soft => '65536'  , hard => '65536',  },
                               'nproc'   => { soft => '2048'   , hard => '16384',   },
                               'memlock' => { soft => '1048576', hard => '1048576',},
                               'stack'   => { soft => '10240'  ,},},
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

class ssh {
  require os

  notice 'class ssh'

  file { "/home/oracle/.ssh/":
    owner  => "oracle",
    group  => "dba",
    mode   => "700",
    ensure => "directory",
    alias  => "oracle-ssh-dir",
  }
  
  file { "/home/oracle/.ssh/id_rsa.pub":
    ensure  => present,
    owner   => "oracle",
    group   => "dba",
    mode    => "644",
    source  => "/vagrant/ssh/id_rsa.pub",
    require => File["oracle-ssh-dir"],
  }
  
  file { "/home/oracle/.ssh/id_rsa":
    ensure  => present,
    owner   => "oracle",
    group   => "dba",
    mode    => "600",
    source  => "/vagrant/ssh/id_rsa",
    require => File["oracle-ssh-dir"],
  }
  
  file { "/home/oracle/.ssh/authorized_keys":
    ensure  => present,
    owner   => "oracle",
    group   => "dba",
    mode    => "644",
    source  => "/vagrant/ssh/id_rsa.pub",
    require => File["oracle-ssh-dir"],
  }        
}

class java {
  require os

  notice 'class java'

  $remove = [ "java-1.7.0-openjdk.x86_64", "java-1.6.0-openjdk.x86_64" ]

  package { $remove:
    ensure  => absent,
  }

  include jdk7

  jdk7::install7{ 'jdk1.7.0_45':
      version              => "7u45" , 
      fullVersion          => "jdk1.7.0_45",
      alternativesPriority => 18000, 
      x64                  => true,
      downloadDir          => "/data/install",
      urandomJavaFix       => true,
      sourcePath           => "/software",
  }

}


class domains{
  require orawls::weblogic

  notice 'class domains'
  $default_params = {}
  $domain_instances = hiera('domain_instances', [])
  create_resources('orawls::domain',$domain_instances, $default_params)
}

class nodemanager {
  require orawls::weblogic, domains

  notify { 'class nodemanager':} 
  $default_params = {}
  $nodemanager_instances = hiera('nodemanager_instances', [])
  create_resources('orawls::nodemanager',$nodemanager_instances, $default_params)
}

class startwls {
  require orawls::weblogic, domains,nodemanager


  notify { 'class startwls':} 
  $default_params = {}
  $control_instances = hiera('control_instances', [])
  create_resources('orawls::control',$control_instances, $default_params)
}

class userconfig{
  require orawls::weblogic, domains, nodemanager, startwls 

  notify { 'class userconfig':} 
  $default_params = {}
  $userconfig_instances = hiera('userconfig_instances', [])
  create_resources('orawls::storeuserconfig',$userconfig_instances, $default_params)
} 

class machines{
  require userconfig

  notify { 'class machines':} 
  $default_params = {}
  $machines_instances = hiera('machines_instances', [])
  create_resources('orawls::wlstexec',$machines_instances, $default_params)
}

#class datasources{
#  require machines
#
#  $default_params = {}
#  $datasource_instances = hiera('datasource_instances', [])
#  create_resources('orawls::wlstexec',$datasource_instances, $default_params)
#}


class server_templates{
  require machines

  notify { 'class server_templates':} 
  $default_params = {}
  $server_templates_instances = hiera('server_templates_instances', [])
  create_resources('orawls::wlstexec',$server_templates_instances, $default_params)
}



class cluster{
   require server_templates

  notify { 'class cluster_instances':} 
  $default_params = {}
  $cluster_instances = hiera('cluster_instances', [])
  create_resources('orawls::wlstexec',$cluster_instances, $default_params)

}

class coherence{
   require cluster

  notify { 'class coherence_instances':} 
  $default_params = {}
  $coherence_instances = hiera('coherence_instances', [])
  create_resources('orawls::wlstexec',$coherence_instances, $default_params)

}

class jmsservers{
   require coherence

  notify { 'class jmsservers_instances':} 
  $default_params = {}
  $jmsservers_instances = hiera('jmsservers_instances', [])
  create_resources('orawls::wlstexec',$jmsservers_instances, $default_params)

}

class jmsmodules{
   require jmsservers

  notify { 'class jmsmodules_instances':} 
  $default_params = {}
  $jmsmodules_instances = hiera('jmsmodules_instances', [])
  create_resources('orawls::wlstexec',$jmsmodules_instances, $default_params)

}

class subdeployments{
   require jmsmodules

  notify { 'class subdeployments_instances':} 
  $default_params = {}
  $subdeployments_instances = hiera('subdeployments_instances', [])
  create_resources('orawls::wlstexec',$subdeployments_instances, $default_params)

}

class queues{
   require subdeployments

  notify { 'class queues_instances':} 
  $default_params = {}
  $queues_instances = hiera('queues_instances', [])
  create_resources('orawls::wlstexec',$queues_instances, $default_params)

}

class cf{
   require queues

  notify { 'class cf_instances':} 
  $default_params = {}
  $cf_instances = hiera('cf_instances', [])
  create_resources('orawls::wlstexec',$cf_instances, $default_params)

}



class pack_domain{
  require cf

  notify { 'class pack_domain':} 
  $default_params = {}
  $pack_domain_instances = hiera('pack_domain_instances', $default_params)
  create_resources('orawls::packdomain',$pack_domain_instances, $default_params)
}

class goldengate_11g {
   require orawls::weblogic

      oradb::goldengate{ 'ggate11.2.1_java':
                         version                 => '11.2.1',
                         file                    => 'V38714-01.zip',
                         tarFile                 => 'ggs_Adapters_Linux_x64.tar',
                         goldengateHome          => "/opt/oracle/ggate_java",
                         user                    => 'ggate',
                         group                   => 'dba',
                         downloadDir             => '/data/install',
                         puppetDownloadMntPoint  => '/software',
      }

}

