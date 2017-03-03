if [ ! -d target ]
then 
    mvn compile
    mvn dependency:copy-dependencies
fi

java -classpath "./target/classes:./target/dependency/arcus-java-client-1.9.6.jar:./target/dependency/ehcache-core-2.6.0.jar:./target/dependency/zookeeper-3.4.5.jar:./target/dependency/jline-0.9.94.jar:./target/dependency/junit-3.8.1.jar:./target/dependency/netty-3.2.2.Final.jar:./target/dependency/log4j-1.2.16.jar:./target/dependency/slf4j-api-1.6.1.jar:./target/dependency/slf4j-log4j12-1.6.1.jar" CheckKeyNode
