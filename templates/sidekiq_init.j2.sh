#!/bin/bash
### BEGIN INIT INFO
# Provides:     sidekiq beta
# Required-Start:   $syslog $remote_fs
# Required-Stop:    $syslog $remote_fs
# Should-Start:     $local_fs
# Should-Stop:      $local_fs
# Default-Start:    2 3 4 5
# Default-Stop:     0 1 6
# Short-Description:    sidekiq beta - asynchronous rails
# Description:      sidekiq beta - asynchronous rails
### END INIT INFO

#Variable Set
NAME=sidekiq
SIDEKIQ="sidekiq"
APP="{{ app_name }}"
APP_DIR="/home/{{ user }}/projects/$APP/current"
APP_CONFIG="$APP_DIR/config"
LOG_FILE="$APP_DIR/log/${NAME}_$APP.log"
LOCK_FILE="$APP_DIR/${NAME}_$APP-lock"
PIDDIR="/var/run"
PID_FILE="$PIDDIR/${NAME}_$APP.pid"
GEMFILE="$PIDDIR/Gemfile"
APP_ENV="production"
BUNDLE="bundle"

#### !IMPORTANT PIDFILE an LOGFILE should be defined in RAISL_ROOT/config/sidekiq.yml
### so not sure -P and -L are necessary here :
START_CMD="$BUNDLE exec $SIDEKIQ -d -e $APP_ENV -P $PID_FILE -L $LOG_FILE"
RETVAL=0


start() {

  status
  if [ $? -eq 1 ]; then
    [ `id -u` -eq 0 ] || (echo "$SIDEKIQ runs as root only .."; exit 5)
    [ -d $APP_DIR ] || (echo "$APP_DIR not found!.. Exiting"; exit 6)
    cd $APP_DIR
    echo "Starting $SIDEKIQ message processor .. "
    $START_CMD >> $LOG_FILE 2>&1
    RETVAL=$?
    #Sleeping for 8 seconds for process to be precisely visible in process table - See status ()
    sleep 8
    #[ $RETVAL -eq 0 ] && touch $LOCK_FILE
    return $RETVAL
  else
    echo "$SIDEKIQ message processor is already running .. "
  fi


}

stop() {

    echo "Stopping $SIDEKIQ message processor .."
    SIG="INT"
    kill -$SIG `cat  $PID_FILE`
    RETVAL=$?
    #[ $RETVAL -eq 0 ] && rm -f $LOCK_FILE
    return $RETVAL
}


status() {
  ps -ef | grep "sidekiq [0-9]*.[0-9]*.[0-9]* $APP_ENV" | grep -v grep
  return $?
}


case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status

        if [ $? -eq 0 ]; then
             echo "$SIDEKIQ message processor is running .."
             RETVAL=0
         else
             echo "$SIDEKIQ message processor is stopped .."
             RETVAL=1
         fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 0
        ;;
esac
exit $RETVAL