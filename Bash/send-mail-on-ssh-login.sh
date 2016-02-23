#!/bin/sh

SUBJECT="SSH LOGIN DETECTED ("`hostname`")"         # Betreff

EMAIL="someone@gmail.de"                        # Empfänger
EMAILMESSAGE="/tmp/emailmessage.txt"                # Temporäre Datei für den Mailtext

# Inhalt der E-Mail
echo "Hallo $EMAIL so eben wurde ein SSH Login auf der Maschine erkannt. Bitte pruefe die nachfolgenden Logindaten!" > $EMAILMESSAGE
echo "" >> $EMAILMESSAGE
echo "USER: " `whoami` >> $EMAILMESSAGE
echo "HOST: " `hostname` >> $EMAILMESSAGE
echo "DATUM: " `date` >> $EMAILMESSAGE
echo "FROM: " `who | cut -d"(" -f2 | cut -d")" -f1` >> $EMAILMESSAGE
#echo "UNAME: " `uname -a` >> $EMAILMESSAGE
#echo "" >> $EMAILMESSAGE                          # Leerzeile

# send an email using /bin/mail
mail -s "$SUBJECT" "$EMAIL" < $EMAILMESSAGE        # Mail senden

# Daten bereinigen
rm $EMAILMESSAGE                                   # Temporäre Datei löschen
