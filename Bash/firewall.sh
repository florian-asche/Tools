#!/bin/bash
####
### FIREWALL SCRIPT
####

echo ""
echo "#############################"
echo "###    FIREWALL SCRIPT    ###"
echo "#############################"
echo ""

## VARIABLES
SUBJECT="FIREWALL SET ("`hostname`")"           # Betreff
EMAIL="root"                                    # Empfänger
EMAILMESSAGE="/tmp/emailmessage.txt"            # Temporäre Datei für den Mailtext
IPT="/sbin/iptables"
IPT6="/sbin/ip6tables"

# Array of trusted IPs
TRUSTED=(
  78.0.0.0/8           # UnityMedia
  127.0.0.1            # vServer
  192.168.0.0/24       # Private
  192.168.178.0/24     # Private
)

TRUSTED6=(
  133:713:3d:337::/64 #own V6
)


############################################################################################
############################################################################################
############################################################################################

# Inhalt der E-Mail
echo "Hallo $EMAIL so eben wurde das Firewall Script ausgefuehrt. Bitte pruefe die nachfolgenden Logs!" > $EMAILMESSAGE
echo "" >> $EMAILMESSAGE
echo "USER: " `whoami` >> $EMAILMESSAGE
echo "HOST: " `hostname` >> $EMAILMESSAGE
echo "DATUM: " `date` >> $EMAILMESSAGE
echo "FROM: " `who | cut -d"(" -f2 | cut -d")" -f1` >> $EMAILMESSAGE
#echo "UNAME: " `uname -a` >> $EMAILMESSAGE

echo "" >> $EMAILMESSAGE                          # Leerzeile
echo "" >> $EMAILMESSAGE                          # Leerzeile

# Flush previous rules
$IPT -F
$IPT -F INPUT
$IPT -F OUTPUT
$IPT -F FORWARD

$IPT6 -F
$IPT6 -F INPUT
$IPT6 -F OUTPUT
$IPT6 -F FORWARD


# Set Defaults
$IPT -P INPUT DROP
$IPT6 -P INPUT DROP
#$IPT -A INPUT -j LOG --log-level warning -m limit --limit 5/min --log-tcp-options --log-tcp-sequence --log-ip-options --log-prefix "FW-INPUT dropped:"

#Create a new chain called LOGGING
#iptables -N LOGGING
#All the remaining incoming packets will jump to the LOGGING chain
#iptables -A INPUT -j LOGGING
#Log the incoming packets to syslog (/var/log/messages). This line is explained below in detail.
#iptables -A LOGGING -m limit --limit 2/min -j LOG --log-prefix "IPTables-Dropped: " --log-level 4
#Finally, drop all the packets that came to the LOGGING chain. i.e now it really drops the incoming packets.
#iptables -A LOGGING -j DROP

$IPT -P OUTPUT ACCEPT
$IPT -P FORWARD DROP

$IPT6 -P OUTPUT ACCEPT
$IPT6 -P FORWARD DROP


## FIREWALL RULES

# Allow loopback
$IPT -A INPUT -i lo -j ACCEPT
$IPT6 -A INPUT -i lo -j ACCEPT

# Allow related and established connections
$IPT -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
$IPT6 -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# Allow SSH and other for trusted IPs
# using array from the
# begining of this file
for iplist in ${TRUSTED[*]}
do
  $IPT -A INPUT -p tcp -m tcp -s $iplist --dport 22 -j ACCEPT   #SSH
  $IPT -A INPUT -p icmp -m icmp --icmp-type 0 -d $iplist -j ACCEPT
  $IPT -A INPUT -p icmp -m icmp --icmp-type 8 -d $iplist -j ACCEPT
done


for iplist in ${TRUSTED6[*]}
do
  $IPT6 -A INPUT -p tcp -m tcp -s $iplist --dport 22 -j ACCEPT   #SSH
#  $IPT6 -A INPUT -p icmp -m icmp --icmp-type 0 -d $iplist -j ACCEPT
#  $IPT6 -A INPUT -p icmp -m icmp --icmp-type 8 -d $iplist -j ACCEPT
done


# Allow HTTPD
$IPT -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
$IPT -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
$IPT6 -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
$IPT6 -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT

# Allow ICMP
#$IPT -A INPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT
#$IPT -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
#$IPT6 -A INPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT
#$IPT6 -A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT


# Blocking all IPs from Blocklist
_input=/root/scripts/firewall/badips.db
while IFS= read -r ip
do
        echo "Banned: $ip" >> $EMAILMESSAGE
        iptables -I INPUT -s $ip -j DROP
done <"${_input}"


#echo "" >> $EMAILMESSAGE                          # Leerzeile
# send an email using /bin/mail
mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE        # Mail senden

# Daten bereinigen
rm $EMAILMESSAGE                                   # Temporäre Datei löschen
