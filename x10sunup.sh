#!/bin/bash

# DoX10 x10sunup.sh
# This isn't really expected to be useful as-is, it's been tailored over the years to work as I like it.
# However, it's really for ideas and whatnot. The code for the weather thing was originally an idea by
# some other person whose name I lost, except it had to be modified to work as the original code would sometimes
# fire after sunset and never perform the actions. It tends to work well, but if you have any kind
# of power outages that can last for longer than your UPS holds, have some other fallback method for your
# X10 devices. I have a second program that runs on the same machine and tries to turn things on and off
# at set times, as well as having an old X10 timer/controller device that does similar.


# depends: ssmtp or msmtp and msmtp-mta. mpack and mailutils are installed but not necessary.
# depends: heyu, sendxmpp (kind of broken these days)
# depends: sunwait, weather (sunwait was diy compile when this was written)

# turns off an X10 module at a specified time based on sunrise and weather conditions.
# needs a serial converter and an X10 serial-to-powerline interface unit. 

# externals: pushover, a gnu social instance, a socialstrap instance, an email service, and an xmpp service. 
# You should know how to set these up. Consult your henway if you don't know.

# This runs on a Wheezy machine. I know sunwait changed on Jessie, so YMMGTZ.


	# mail notification addresses
	mail="an email address"
	xtra="another email address"
	
	# where and who am I. zipcode is for weather. Don't use whoami.
	zipcode=12345
	myname="who_am_i"

	# where are things stored
	dirloc="/mnt/some/dir"

	# sometimes you want an email, sometimes you don't. 
	yesmail=0

	# stuff for telegram
	CHAT_ID="ID number"
	API_KEY="your key"

	# This is the module we're turning off. In this case, it's the front porch.
	module="a2"
	
	# where are we. Use "12.345678N" - needs the ordinal at the end!
	lat="12.345678N"
	lon="23.456789W"

	# set the initial delay
	delay="+1"

	# stuff for posting to a local Gnu Social instance, don't need this to make it work but moar notifications are moar!
     username="username"
     userpass="userpass"
     snurl="https://location.of.gnusocial/instance/index.php"
     ksnnetwork="snoutput.txt"

	# xmpp uid and the who relays your material
	xm="me@some.instance.com"
	sendwho="my@instance.that.sends.stuff.com"


# make sure our file exists
touch "$dirloc""status.txt"
touch "$dirloc""curllog"


#notifiers, should be self explanatory.
function xmppxmpp {
        echo "$myname: $mess" | /usr/bin/sendxmpp -t /home/scripts/mysslcert.crt -f /home/scripts/.sendxmpprc "$xm"
}

function push {
    curl -s -F "token=pushovertoken" \
    -F "user=pushoveruser" \
    -F "title=DoX10 Status Update" \
    -F "message=$1" https://api.pushover.net/1/messages.json
}

function tgrm {
    curl -s -i -X GET -G \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=$mess" \
    "https://api.telegram.org/bot${API_KEY}/sendMessage" >> "$dirloc""curllog";
    echo -e " \n" >> "$dirloc""curllog"
}

# curllog is just a log file to diagnose what's going on. Don't need it.


# quiter used to be a big gnu social instance, this posts to your local instance. 
function quitter { curl -k -u "$username"":""$userpass" -F "status=$mess" $snurl/api/statuses/update.xml --silent --output "$dirloc""$ksnnetwork"; }

# this actually does the telling
function telluser {

	echo "$mess" >> "$dirloc"status.txt
	#echo "$mess" |  /usr/bin/sendxmpp -f /home/chirp/.senddis -t -- "$sendwho"

	if [ $yesmail = 1 ]
        then
                echo "$mess" | mail -s "DoX10: Sundown $(date +%s)" "$mail" "$xtra"
                yesmail=0
	fi

	# removed the line calling socialstrap. It's unlikely that you have that. 
	push "$mess"
	#tgrm # not using this atm, telegram got funny
	quitter
	xmppxmpp
}

# This uses sunwait to find the sunrise time, and then checks the weather to see how long to delay on/off.
# If the if-then doesn't match, it assumes the sky is clear and turns off slightly before sunrise. 

# Check the weather before sunrise.
mess="DoX10: $(date): Waiting to check weather 30 minutes before sunrise."
messbird="DoX10: $(date): Sunrise delta -30 min."
yesmail=0
telluser
/usr/local/bin/sunwait sun up -0:30:00 $lat $lon

# Get the current sky conditions
sky=`/usr/bin/weather "$zipcode" | awk -F': ' '/Sky conditions/ {print $2}'`
delay="-10"

if [ "$sky" == "overcast" ]; then
   delay="+10"
elif [ "$sky" == "mostly cloudy" ]; then
   delay="+20"
elif [ "$sky" == "partly cloudy" ]; then
   delay="+15"
else
   delay="-10"
fi

#wait until sunrise with a delay due to weather, then turn the module off.
mess="DoX10: $(date): Waiting until sunrise delta $delay minutes. Conditions $sky."
telluser
/usr/local/bin/sunwait -v sun up $delay $lat $lon

# Turn off the lamp. Do it a bunch of times in case of noise on the line
mess="DoX10: $(date): Requesting $module be deactivated."
telluser

for i in `seq 1 5`;
	do
		sudo /usr/local/bin/heyu off $module
		sleep 5
	done

mess="DoX10: $(date): Lights off at sunrise delta $delay."
telluser

exit 0

