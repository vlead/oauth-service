#!/bin/sh
sudo fuser -k 8443/tcp
sudo fuser -k 8081/tcp

mvn clean package
sudo java -jar cas-overlay-server-demo/target/cas.war &
sudo java -jar cas-overlay-management-demo/target/cas-management.war 
