#!/bin/bash
function test ()
{
    for i in `seq 1 $1`
    do
        key=`head -c 10 /dev/random | md5`;
        value=`head -c 100 /dev/random | base64`;
        encoded_value=`echo $value | base64`;
        result=`curl --data "key=$key&value=$encoded_value" http://localhost:3000/$2`;
        if [ $result == "OK" ] 
        then
            returned=`curl http://localhost:3000/$2/$key | base64 -D`;
            if [ "$returned" != "$value" ]
            then
                echo "RETURNED VALUE IS INCORRECT: $key $encoded_value" >> errors.log
            fi
        else
           echo "CANNOT INSERT VALUE" >> errors.log
        fi
    done
}

rm errors.log
rm test_collection*

echo $1 $2
for j in `seq 1 $1` 
do
    test $2 test_collection1 &
    test $2 test_collection2 &
done

cat errors.log

