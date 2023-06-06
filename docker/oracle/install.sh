git clone https://github.com/oracle/docker-images.git

cd docker-images
cd OracleDatabase
cd SingleInstance
cd dockerfiles
cd 19.3.0

# https://www.oracle.com/database/technologies/oracle-database-software-downloads.html
# wget https://download.oracle.com/otn/linux/oracle19c/190000/LINUX.X64_193000_db_home.zip

grep -v ^# db_inst.rsp | grep -v ^&

cd ../
./buildContainerImage.sh -v 19.3.0 -e

docker run --name oracle19c -p 1521:1521 -p 5500:5500 -e ORACLE_PDB=orcl =e ORACLE_PWD=passwd -e ORACLE_MEM=2000 -v /var/docker/oracle -d oracle/database:19.3.0-ee
