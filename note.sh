#!/usr/bin/env bash

#date '+%F %H:%M'
up=`date '+%F %H:%M'`
#up="somestr"
echo $up
echo "checking exchange rate..."

exchange_url="https://free.currencyconverterapi.com/api/v6/convert?q=EUR_ZAR&compact=ultra&apiKey=37d938d8589a90570d19"

response=$(curl --write-out "%{http_code}\n" $exchange_url)

echo $response
echo ${response: -3}
echo ${response:11:5}

#response=json_decode(curl_exec($curl))

#echo response["EUR_ZAR"]

echo "success"