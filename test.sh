#!/bin/bash
test ()
{
    for i in {1..100}
    do
        key=$(head -c 10 /dev/random | md5);
        value=$(head -c 100 /dev/random | base64);
        result=$(curl --data "key=$key&value=$value" http://localhost:3000/test_collection)
        if [ $result == "OK" ] 
        then
            returned=$(curl http://localhost:3000/test_collection/$key)
            if [ "$returned" != "$value" ]
            then
                echo "RETURNED VALUE IS INCORRECT: $key $value $returned" >> errors.log
            fi
        else
           echo "CANNOT INSERT VALUE" >> errors.log
        fi
    done
}

rm errors.log

for j in {1..10}
do
    test &
done

cat errors.log

