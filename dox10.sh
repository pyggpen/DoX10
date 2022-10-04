#!/bin/bash

# Script to do simple X10 on-off controls with heyu and a CM11A.
# All times are assumed to be 24-hour.
# Depends: sendxmpp, heyu, snmptools.
# Options: sendmail variant, your favorite IM or push client.
# $act = action requested ( on || off ), $mod = module that should do the action.
# $cmt = a silly comment to let the user know the action was a dummy action.
# Make sure your modules have the proper housecode and module code.
# CF Bulbs, Switching power supplies (computers/chargers,) and motorized equipment
# can destroy X10 signals.

# Put this script in your crontab with */15 * * * *
# This script by BSW, 2015. Share and enjoy.

# This thing is a mess, I know that. It's not intended for general consumption.

# Variables and housekeeping

	ct="$(date +%H:%M)"			# The time in HH:MM format
	dw="$(date +%a)"			# The day-of-week, i.e. Sun, Mon, etc.
#       text=""					# Carrier sms-to-email address
#       mail=""					# A generic email address
#       xtra=""					# An extra email address
        xrcv=""	# Jabber (XMPP) address for notifications
        x10dir="/mnt/some/dir/"			# Where the log files go
        touch "$x10dir"status.txt		# Make sure the log file exists first
	oid="1.3.6.1.4.1.20916.1.8.1.2.7.2.0"
	ra32="192.168.1.202"
	dm=$(date +%M)
	tellme="yes"
	outtemp=`/usr/bin/snmpwalk -v 1 -c public $ra32 $oid | awk '{print $4;}'`
	nofan="1" # don't do the fan section, probably should remove it.
        CHAT_ID="id"
        API_KEY="key"
	username="username"
	userpass="userpass"
	snurl="https://some.gnusocial/instance/index.php"
	ksnnetwork="snoutput.txt"
	dirloc="$x10dir"
	xm="xmppreceiver"
	myname="DoX10"
	sendwho="whoissendingthexmpp"


#	current modules known to the system
#	a2 - Front Porch
# 	a1 - Front Room Corner
#	a3 - Stairwell and Halls
#	a4 - kitchen
#	a5 - Plumbing Fans (changed 04/17/2018)(deleted)
#	b1 - Rear Porch (deleted)
#	b2 - Garage Overhead (deleted)
#	a7 - security lamp (changed 10/22/2018)(on demand)

# CF Bulbs and Switching Power Supplies can destroy X10 signals.
# CF Bulbs and Switching Power Supplies can destroy X10 signals.
# CF Bulbs and Switching Power Supplies can destroy X10 signals.
# CF Bulbs and Switching Power Supplies can destroy X10 signals.
# CF Bulbs and Switching Power Supplies can destroy X10 signals.
# CF Bulbs and Switching Power Supplies can destroy X10 signals.
# CF Bulbs and Switching Power Supplies can destroy X10 signals.
# CF Bulbs and Switching Power Supplies can destroy X10 signals.
# CF Bulbs and Switching Power Supplies can destroy X10 signals.
# CF Bulbs and Switching Power Supplies can destroy X10 signals.

function dox10 {

# Each action is performed 5 times because of AC Line Noise.
# X10 is a pretty slow protocol. Each action takes 25 seconds +
# X10 transmit time to complete. Reduce the number of loops
# if you're confident about the quality of the signals. I'm not.

for i in `seq 1 5`;
        do
                sudo /usr/local/bin/heyu $act $mod
                sleep 5
        done

# Tell the user the actions were requested

#echo "$telluser" /usr/bin/sendxmpp -f /home/chirp/.senddis -t -- "$sendwho"
#sleep 5
echo "x10: $ct: Module $mod has been asked to be $act. $cmt" >> "$x10dir"status.txt

#Set up the message

telluser="x10: $(date): $mod: $act"

# Tell Twitter

ha ha no, twitter is communism.


# Tell Chirper

# This was for socialstrap. It's unlikely you have it.

# Put any other notifications required here.

if [ "$tellme" = "yes" ]
	then
		push "DoX10: Module $mod has been requested to be $act. Last temperature recorded was $outtemp." >> "$x10dir""pushlog.txt"
                mess="DoX10: Module $mod has been requested to be $act. Last temperature recorded was $outtemp."
		#tgrm
		quitter
		xmppxmpp
fi
}

function push {
    curl -s -F "token=token" \
    -F "user=user" \
    -F "title=DoX10 Status Update" \
    -F "message=$1" https://api.pushover.net/1/messages.json
}

function tgrm {
    curl -s -i -X GET -G \
    --data-urlencode "chat_id=${CHAT_ID}" \
    --data-urlencode "text=$mess" \
    "https://api.telegram.org/bot${API_KEY}/sendMessage" >> "$x10dir""curllog";
    echo -e " \n" >> "$x10dir""curllog"
}


function xmppxmpp {
	echo "$myname: $mess" | /usr/bin/sendxmpp -t /home/scripts/mysslcert.crt -f /home/scripts/.sendxmpprc "$xm"
}

function quitter { curl -k -u "$username"":""$userpass" -F "status=$mess" $snurl/api/statuses/update.xml --silent --output "$dirloc""$ksnnetwork"; }

if [ "$ct" = "22:15" ] || [ "$ct" = "06:00" ]
	then
		mod="a7"
		act="on"
		dox10
fi

if [ "$ct" = "06:45" ] || [ "$ct" = "23:15" ]
	then
		mod="a7"
		act="off"
	 	dox10
fi

# ct="22:00" # test

# The actual logic is simple OR to determine if the time and DOW are correct
# It doesn't hurt a module to make a request to turn on if it's already on,
# similar with off. 

# Turn the Corner (a2) off at 9:30P
# turn the stairwell (a3) and corner off at 6:15A
# turn the stairwell off at 10:15P
# We don't care if it's not on.

if [ "$ct" = "22:00" ]
	then
		mod="a1"
		act="off"
		dox10

		mod="a4"
		act="off"
		dox10

# This section tries to turn the front porch lamp on at 10PM
# This is only a problem if the server rebooted sometime after the sundown was active

                mod="a2"
                act="on"
                dox10
fi

if [ "$ct" = "05:30" ]
	then
                mod="a1"
                act="off"
                dox10
                mod="a3"
                dox10
fi

if [ "$ct" = "22:15" ]
	then
		mod="a3"
		act="off"
		dox10
fi

# Turn the Stairwell on at 20:45 and 5:45.
# We can turn corner on too. If it's already on who cares?
# The corner turns on with a different script that looks for sunset,
# but not in the morning, which is just on for a short time so we don't
# fall over in the dark.
# Not on Saturday or Sunday, because schedules will be different.


if [ "$ct" = "20:00" ]
	then
		mod="a1"
		act="on"
		dox10

		mod="a4"
		act="on"
		dox10
fi


if [ "$ct" = "20:30" ]
	then
		if [ "$dw" = "Fri" ] || [ "$dw" = "Sat" ]
			then
				mod="a1"
				act="on"
				dox10
			else
				mod="a1"
				act="on"
				dox10
				mod="a3"
				dox10
			fi
fi

if [ "$ct" = "05:00" ]
	then
		if [ "$dw" = "Sun" ] || [ "$dw" = "Sat" ]
			then
				mod="a99"
				act="nothing"
				# do nothing here
			else
				mod="a3"
				act="on"
				dox10
				mod="a1"
				dox10
			fi
fi

if [ "$ct" = "12:15" ]
	then
		massmess="1"
		mod="a1"
		act="off"
		dox10
		massmess="999"
		mod="a2"
		dox10
                massmess="999"
		mod="a3"
		dox10
                massmess="999"
		mod="a4"
		dox10
		massmess="999"
#	if [ "$outtemp" > "3100" ]
#		then
#			mod="a5"
#			act="off"
#			dox10
#	fi
fi

massmess="0"

outtemp=`/usr/bin/snmpwalk -v 1 -c public $ra32 $oid | awk '{print $4;}'`
last=$(<"$x10dir""lastaction.txt")
echo "$outtemp" > "$x10dir""lasttemp.txt"



# This section reads a temperature from the RA32 device (sensor 7 in this case)
# which is the outside temp. If it drops below 22F (2200) then it tries to turn
# the plumbing fan module on. It also tries to do that every hour (while temp is in range)
# just in case one of the signals got lost.
# If the temp goes above 31F (3100) then it tries to turn the module off.
# Probably should add a section that tries to turn the module off once a day
# if the temp is in range, just in case as well...

# This isn't really needed anymore, because the wall is insulated now.
# We should change it to A5
# looks like I said get rid of it anyway, guess I should do that?


if [ "$nofan" = "0" ]  # skip this section if nofan=1
	then


if (( "$outtemp" < "2200" ))
	then
		if [ "$last" = "on" ]
			then
				if [ "$dm" = "00" ]
					then
						mod="a5"
						act="on"
						tellme="no"
						dox10
						echo "on" > "$x10dir""lastaction.txt"
						echo "x10: Last temp: ""$outtemp" >> "$x10dir""status.txt"
				fi
		else
			if [ "$last" = "off" ]
				then
					mod="a5"
					act="on"
					dox10
					echo "on" > "$x10dir""lastaction.txt"
					echo "x10: Last temp: ""$outtemp" >> "$x10dir""status.txt"
			fi
		fi
fi

if (( "$outtemp" > "3100" ))
	then
		if [ "$last" = "on" ]
			then
				mod="a5"
				act="off"
				dox10
				echo "off" > "$x10dir""lastaction.txt"
				echo "x10: Last temp: ""$outtemp" >> "$x10dir""status.txt"
		fi
fi


fi

# test - only run for debugging!
#mod="a5"
#act="off"
#dox10

exit 0
