#!/usr/bin/env bash

# # AKO edits
# # change isbig=false to background 1920x1080, moon image 
# # change base best_small.tif to nambest.tif
# check if connected, allow 30s to establish connection (retry once)
# check if a reasonable amount of time has elapsed before updating
(
#go into directory of script no matter where it is called.
wdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd $wdir

echo "=== Update phase ==="
date
update=`date '+%F %H:%M'`
echo "$update"

if ping -c 1 google.com; then
    echo "It appears you have a working internet connection"
else
	echo "No internet, retrying in 30 seconds"
	sleep 30
	if ping -c 1 google.com; then
		echo "Internet connection found on 2nd attempt"
	else
		echo "No internet, exiting\n\n"
		exit 1
	fi
fi

#isbig=false means background  5641x3650, moon image = 3840x2160, download 5,562MB
#isbig=true means background  8192x5641, moon image = 5760x3240, download 12MB
isbig=false

#get current hour of the year
num=$((10#$(date --utc +"%j")*24-23+10#$(date --utc +"%H")))
#get illumination% from text file I edited down from one found here "https://svs.gsfc.nasa.gov/vis/a000000/a004800/a004874/"
phase=$(sed "$num q;d" phase.txt)
#days in moon cycle so far
age=$(sed "$num q;d" age.txt)
#caption
text="Phase: $phase% Days: $age     "
text2="Updated: $update     "
im="moon.$num.tif"

# check time elapsed since last update (avoid redownload)
last=$(<moons.log)
echo "$last"
if [[ -z "$last" || ! "$last" =~ ^[0-9]+$ ]]; then
	echo "No moon in moons.log (continuing)"
	# continue anyway
elif ((($num - $last) < 2)); then
	echo "Not doing moon $num, last moon was $last\n\n"
	exit 1
else
	echo "Latest moon $num, to replace $last"
fi

echo "download and etc..."

# check exchange rate EUR to ZAR
echo "checking exchange rate..."
exchange_url="https://free.currencyconverterapi.com/api/v6/convert?q=EUR_ZAR&compact=ultra&apiKey=37d938d8589a90570d19"
response=$(curl --write-out "%{http_code}\n" $exchange_url)
echo "received response: $response"


if [ $isbig = true ]
then
	curl -LO "https://svs.gsfc.nasa.gov/vis/a000000/a004800/a004874/frames/5760x3240_16x9_30p/plain/$im"

	wait
	#replace orginal file with designated background file and add background and caption with imagemagick
	composite -gravity center $im best.tif back.tif 
	convert -font ubuntu -fill '#b1ada7' -pointsize 80 -gravity east -draw "text 150,1800 '$text'" back.tif back.tif
else
	curl -LO "https://svs.gsfc.nasa.gov/vis/a000000/a004800/a004874/frames/3840x2160_16x9_30p/plain/$im"

	wait
	#replace orginal file with designated background file and add background and caption with imagemagick
	composite -gravity center $im nambest.tif back.tif 
	convert -font ubuntu -fill '#b1ada7' -pointsize 50 -gravity east -draw "text 100,1200 '$text'" back.tif back.tif
	convert -font ubuntu -fill '#b1ada7' -pointsize 36 -gravity east -draw "text 124,1260 '$text2'" back.tif back.tif
	if [ ${response: -3} = 200 ]
	then 
		rate=${response:11:5}
		convert -font ubuntu -fill '#b1ada7' -pointsize 36 -gravity east -draw "text 160,1300 'EUR:ZAR $rate'" back.tif back.tif
	else
		echo "invalid exchange response, ignoring"
	fi
fi
echo $wdir
echo $im

#first half of gsettings command forces background to reload, by assigning an empty picture and immediately replacing it with the updated back.tif file.
gsettings set  org.cinnamon.desktop.background picture-uri "" && gsettings set  org.cinnamon.desktop.background picture-uri "file://$wdir/back.tif"

#remove downloaded moon file as not to use up storage.
rm $im

echo "\n\n\n"

# log the last moon, to avoid redownload
(echo $num) > moons.log

) 2>&1 | tee -a ~andre/logs/moonback.log
