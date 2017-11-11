#!/bin/sh

mvn clean package
cd vlead-cas-server
docker build -t vlead-cas-server .
docker run --name server -p 127.0.0.1:8443:8443 -i -d vlead-cas-server
cd ../vlead-cas-management/
docker build -t vlead-cas-management .
docker run --name management -p 127.0.0.1:8081:8081 -i -d vlead-cas-management
