#!/bin/bash

if test ! -e sid ; then
    echo $HOSTNAME`pwd` | md5sum | awk '{print $1}' > sid;
fi

MAIN_CLASS="${main.class}"

JAVA_OPTS="-Xms2048m -Xmx2048m -XX:NewSize=1024m -XX:PermSize=512m -server -XX:+DisableExplicitGC -verbose:gc -XX:+PrintGCDateStamps -XX:+PrintGCDetails"

JAVA_PROPS="-Dtest -Dcom.kepler.host.impl.serverhost.sid=`cat sid`"

CLASSPATH=.:..:../conf
for i in ./../lib/*.jar; do
    CLASSPATH="$CLASSPATH":"$i"
done

echo "java $JAVA_OPTS $JAVA_PROPS -cp $CLASSPATH $MAIN_CLASS"

nohup java $JAVA_OPTS $JAVA_PROPS -cp $CLASSPATH $MAIN_CLASS >> ../log/out.log 2>&1 &
