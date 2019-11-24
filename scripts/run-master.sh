#!/bin/bash

export SPARK_DIST_CLASSPATH=$(hadoop classpath)

. "$SPARK_HOME/sbin/spark-config.sh"

. "$SPARK_HOME/bin/load-spark-env.sh"

mkdir -p $SPARK_LOG

ln -sf /dev/stdout $SPARK_LOG/spark-master.out

CMD="$SPARK_HOME/bin/spark-class org.apache.spark.deploy.master.Master"

if [[ -z "${SPARK_HOST}" ]]; then
    echo "setting host to $(hostname -f)"
    CMD="$CMD -h $(hostname -f)"
else
    echo "setting host to $SPARK_HOST"
    CMD="$CMD -h $SPARK_HOST"
fi
CMD="$CMD >> $SPARK_LOG/spark-master.out"
exec $CMD 