#!/bin/bash

export SPARK_DIST_CLASSPATH=$(hadoop classpath)

. "$SPARK_HOME/sbin/spark-config.sh"

. "$SPARK_HOME/bin/load-spark-env.sh"

mkdir -p $SPARK_LOG

ln -sf /dev/stdout $SPARK_LOG/spark-worker.out

CMD="$SPARK_HOME/bin/spark-class org.apache.spark.deploy.worker.Worker $SPARK_MASTER"
echo "spark master is $SPARK_MASTER"

if [[ -z "${SPARK_HOST}" ]]; then
    echo "setting host to $(hostname -f)"
    CMD="$CMD -h $(hostname -f)"
else
    echo "setting host to $SPARK_HOST"
    CMD="$CMD -h $SPARK_HOST"
fi

if [[ -z "${SPARK_WORKER_CORES}" ]]; then
    echo "Using all cores"
else
    CMD="$CMD -c $SPARK_WORKER_CORES"
fi

if [[ -z "${SPARK_WORKER_MEMORY}" ]]; then
    echo "Using all memory (-1G)"
else
    CMD="$CMD -m $SPARK_WORKER_MEMORY"
fi
CMD="$CMD >> $SPARK_LOG/spark-master.out"
exec $CMD
