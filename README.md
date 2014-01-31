vagrant-wls12.1.2-coherence-goldengate
======================================

creates a patched 12.1.2 WebLogic cluster ( oradb, adminwls , nodewls1, nodewls2 )


JDK
- jdk-7u45-linux-x64.tar.gz

weblogic 12.1.2
- wls_121200.jar

database 11.2.0.4
- p13390677_112040_Linux-x86-64[1-7].zip

goldengate 12.1.2
- 121200_fbo_ggs_Linux_x64_shiphome.zip
- V38714-01.zip ( Oracle GoldenGate Java Adapters 11.2.1 )

user accounts
- OS oracle, pw oracle
- OS vagrant, pw vagrant
- OS ggate, pw oracle
- OS root, pw vagrant
- Oracle db sys, pw Welcome01
- WebLogic weblogic, pw weblogic1 

# database server with goldengate  
vagrant up oradb

do the following GoldenGate changes
- oracle_changes.txt  ( set db in archivemode , goldengate db setup )
- ggate_12.1.2_changes.txt for GoldenGate Capture

# admin server  
vagrant up adminwls
- ggate_java_changes.txt for Coherence sync

# node1  
vagrant up nodewls1

# node2  
vagrant up nodewls2

