#!/bin/bash
test ()
{
    for i in {1..100}
    do
        key=$(head -c 100 /dev/random | md5);
        value=$(head -c 1000 /dev/random | base64);
        result=$(curl --data "key=$key&value=$value" http://localhost:8080/test_collection)
        if [ $result == "OK" ] 
        then
            if [ $(curl http://localhost:8080/test_collection/$key) != $value ]
            then
                echo "ERROR" > errors.log
            fi
        else
           echo "ERROR" > errors.log
        fi
    done
}

for j in {1..10}
do
    test &
done

