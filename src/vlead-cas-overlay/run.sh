#!/bin/sh

cp ../../../src/vlead-cas-overlay/public_private_keys/thekeystore public_private_keys/thekeystore   
cp ../../../src/vlead-cas-overlay/vlead-cas-server/src/main/resources/truststore.jks vlead-cas-server/src/main/resources/

sudo fuser -k 8443/tcp
sudo fuser -k 8081/tcp

mvn clean package

java -jar -Djava.net.useSystemProxies=true vlead-cas-server/target/cas.war

java -jar -Djava.net.useSystemProxies=true cas-overlay-management-demo/target/cas-management.war 
