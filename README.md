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


# database server with goldengate  
vagrant up oradb

# admin server  
vagrant up adminwls

# node1  
vagrant up nodewls1

# node2  
vagrant up nodewls2

