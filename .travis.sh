#!/bin/sh
set -v
exitcode=0

cd test

COVERALLS=true bundle exec rails server 3>&1 > log &
PID=$!

sleep 5

for record in records/*; do
    bundle exec ./replay-record.rb $record
    if [ $? != 0 ]; then
      exitcode=1
    fi
done

echo $PID
ps ax| grep $PID
kill -2 $PID
wait $PID

echo "---------------------------------------"
cat log

exit $exitcode
