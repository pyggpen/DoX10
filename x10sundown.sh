#!/bin/bash

# DoX10 x10sundown.sh
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
# This one is a bit messier than the other one, it was written first.
# to-do, move tokens to variables, clean this stupid thing up.

# There's a lot of garbage in here because it used to be a combination of SMS and email messages, but SMS doesn't work via
# gateways anymore. Working on that one.


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

	# some unique stuff for here
	dirloc="/where/the/scripts_are"


# make sure our file exists
touch "$dirloc""status.txt"
touch "$dirloc""curllog"
touch "$dirloc""status.txt"





# All the tell user functions
function xmppxmpp {
        echo "$myname: $mess" | /usr/bin/sendxmpp -t /home/scripts/mysslcert.crt -f /home/scripts/.sendxmpprc "$xm"
}

# to-do, move the tokens to the variables. But they never change mother, why should I? Shaddup kid and eat your variables!
function push {
    curl -s -F "token=pushovertoken" \
    -F "user=pushoveruser" \
    -F "title=DoX10 Status Update" \
    -F "message=$1" https://api.pushover.net/1/messages.json
}

function tgrm {
    curl -s -i -X GET -G \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=$tellu" \
    "https://api.telegram.org/bot${API_KEY}/sendMessage" >> "$dirloc""curllog";
    echo -e " \n" >> "$dirloc""curllog"
}

function quitter { curl -k -u "$username"":""$userpass" -F "status=$mess" $snurl/api/statuses/update.xml --silent --output "$dirloc""$ksnnetwork"; }

function telluser {

echo "$tellu" >> "$dirloc"status.txt
echo "$tellu" /usr/bin/sendxmpp -f /home/chirp/.senddis -t -- "$sendwho"

if [ $yesmail = 1 ]
	then
		echo "$tellu" | mail -s "x10: Sundown $(date +%s)" "$mail" "$xtra"
		yesmail=0
fi


# Tell ########

# Removed the line for socialstrap, it's unlikely you have that.

# More notification

push "$tellu" >> "$dirloc""pushlog.txt"
#tgrm
mess="$tellu"
quitter
xmppxmpp
}

# Let the user know we've started.
tellu="x10: $(date): Waiting to check weather 30 minutes before sunset."
tellup="x10: $(date): Sunset delta -30."
yesmail=0
telluser

/usr/local/bin/sunwait sun down -0:30:00 $lat $lon

tellu="x10: $(date): Checking weather..."
tellup="x10: $(date): Checking weather..."
yesmail=0
telluser

# New weather routine Sep 6 2016 because NOAA changed where data is located. Delete old when verified!
# deleted the old routines. who knows when.

sky=`/usr/bin/weather "$zipcode" | awk -F': ' '/Sky conditions/ {print $2}'`
delay="+20"

if [ "$sky" == "overcast" ]; then
   delay="-15"
elif [ "$sky" == "mostly cloudy" ]; then
   delay="-10"
elif [ "$sky" == "partly cloudy" ]; then
   delay="+5"
else
   delay="+20"
fi

tellu="x10: $(date): Conditions $sky, Delay $delay."
tellup="x10: $(date): Conditions $sky, Delay $delay."
yesmail=0
telluser

# Turn the internal lamp on at 1/2 hour before sunset. If the time is >2000h<2130h then the lamp is on.
# In this case, module a1 is a lamp in the main room that turns on at a certain time. Used to be sunset was
# before bedtime (sometimes,) now I just turn it on 1/2 hour before sunset. Gotta clean this logic up.

dh=$(date +%k)

if [ "$dh" -ge "21" ]
        then
                echo "x10: $(date): ...it's too late for the corner lamp to turn on." >> "$dirloc""status.txt"
                tellu="x10: $(date): It's later than you think. A1 is not turned on."
                tellup="x10: $(date): A1 was not turned on because time is >2100h"
                yesmail=0
                telluser
        else
                for i in `seq 1 5`;
                do
                        sudo /usr/local/bin/heyu on a1
                        sleep 5
                done

#               tellu="x10: $(date): a1 on at sunset delta $delay."
		tellu="X10: $(date): a1 on at sunset delta -30."
                tellup="x10: module a1 is active"
                yesmail=0
                telluser

fi

# Tell the user, and the logs
echo "Waiting for sunset delta $delay" >> "$dirloc"status.txt
tellu="x10: $(date): Conditions $sky. Lights scheduled at sunset delta $delay minutes."
tellup="x10: $(date): Conditions $sky: Delay $delay min"
yesmail=1
telluser

# Do the actual waiting!
/usr/local/bin/sunwait -v sun down $delay $lat $lon

# Turn on the lamp. Do it a bunch of times in case of noise on the line
tellu="x10: $(date): Sundown module routines activated."
#echo $tellu |  /usr/bin/sendxmpp -f /home/chirp/.senddis -t -- "$sendwho"
#tgrm

for i in `seq 1 5`;
	do
#		sudo /usr/local/bin/heyu on a1
#		sleep 5
		sudo /usr/local/bin/heyu on a2
		sleep 5

	done

        push "x10: $(date): a2 has been requested to be on." >> "$dirloc""pushlog.txt"
        tellu="x10: $(date): a2 on at sunset delta $delay."
        tellup="x10: modules a2 is active"
        yesmail=0
	telluser

# All done!

exit 0
