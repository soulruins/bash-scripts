#!/bin/bash

#set -x
# ������ �������������:
# ./weather_slack.sh "general" "today" "������ �� �������"
# ./weather_slack.sh "general" "tommorow" "������ �� ������"
token="<your_api>" #������� ���� API-���� https://api.slack.com/web
city_code="4368" # ��� ������, �� ��������� - ������ (4368)
INFO_URL="https://slack-files.com" # ���� ���������� � ���� (������)
fact_file="/home/weather_facts.txt" # �������������� ����� � ������� � ������, ���� ��� ����� (������ ���� � ����� ������, ������� ������� randomize-lines)
###
channel="$1" # ��� ������, ����������� ������ ���������� ��� ������� �������
username="$3" # ��� ����, ����������� ������� ���������� ��� ������� �������
#icon=":weather:"
### ����� �� ������
tmpdir="/tmp"
tmp_file1="$tmpdir/forecast.txt"
tmp_file2="$tmpdir/forecast2.txt"
tmp_file3="$tmpdir/forecast3.txt"
###
if [ $2 = "tommorow" ]; then
	firstday="tbwdaily2"
	lastday="tbwdaily3"
else
	firstday="tbwdaily1"
	lastday="tbwdaily2"
fi
if [ -f $fact_file ]; then
	fact=$(rl -c1 $fact_file)
fi
### ���������
echo "*������� �������� �������*" > $tmp_file1
CITY_URL="https://www.gismeteo.ru/city/daily/$city_code/"
curl $CITY_URL 2>/dev/null \
| sed -nre '/section higher/,/�� ��. ��./p' \
| sed -r 's/(.*)class="png" title="(.*)" style="background-image: url\(\/\/(.*)\)"><br \/><\/dt>/> ������: \3/' \
| sed -r '/section higher|cloudness|wicon wind|crumb|scity|\/div|value m_temp f|m_wind mih|m_wind kmh|\/dl|class="temp|wicon barp|dt/d' \
| sed 's/+/%2B/' \
| sed -r 's/(.*)class="type(.*)>(.*)<\/h2>/> �����: \3/' \
| sed -r 's/(.*)<dd(.*)td>(.*)<\/td(.*)\/dd>/> ������: \3/' \
| sed -r 's/(.*)<dd class=(.*)>(.*)<span class="meas(.*)span><\/dd>/> ����������� �������: *\3 C*/' \
| sed -r 's/(.*)value m_wind ms(.*)>(.*)<span class="unit">(.*)<\/span><\/dd>/> �����: \3 \4/' \
| sed -r 's/(.*)value m_press torr(.*)>(.*)<(.*)>(.*)<\/span><\/dd>/> ��������: \3 \5/' \
>> $tmp_file1
icon="$(cat $tmp_file1 | grep "������:" | sed -r 's/> ������:\s(.*)/\1/')"
sed -i '3d' $tmp_file1
echo "*$username*" >> $tmp_file1
printf "> *������� �� ����*\n#NIGHT\n" >> $tmp_file1
printf "> *������� �� ����*\n#MORNING\n" >> $tmp_file1
printf "> *������� �� ����*\n#DAY\n" >> $tmp_file1
printf "> *������� �� �����*\n#EVEN\n" >> $tmp_file1
curl $CITY_URL 2>/dev/null \
| sed -nre "/$firstday/,/$lastday/p" \
| sed -r '/clicon/d' \
| sed -r 's/(.*)����(.*)<\/th>/> *������� �� ����*/' \
| sed -r 's/(.*)����(.*)<\/th>/> *������� �� ����*/' \
| sed -r 's/(.*)����(.*)<\/th>/> *������� �� ����*/' \
| sed -r 's/(.*)�����(.*)<\/th>/> *������� �� �����*/' \
| sed -r 's/(.*)class="cltext">(.*)<\/td>/> \2 :white_small_square:/' \
| sed -r 's/(.*)<td class="temp"><span class=(.*)>(.*)<\/span><span class=(.*)>(.*)<\/span><\/td>/*\3 C* :white_small_square:/' \
| sed -r 's/(.*)<td><span class=(.*)m_press(.*)>(.*)<\/span><span class=(.*)m_press(.*)>(.*)<\/span><span class=(.*)m_press(.*)>(.*)<\/span><\/td>/��������: \4 �� ��. ��. :white_small_square:/' \
| sed -r 's/(.*)<td><dl class="wind"><dt class=(.*) title="(.*)">(.*)<\/dt><dd><span class=(.*)m_wind(.*)>(.*)<\/span><span class=(.*)m_wind(.*)>(.*)<\/span><span class=(.*)m_wind(.*)>(.*)<\/span><\/dd><\/dl><\/td>/�����: \3, \7 �%2F� :white_small_square:/' \
| sed -r 's/(.*)<td>([0-9]{2})<\/td>/���������: \2%/' \
| grep '������� ��\|���������:\|:white_small_square:\|��������:\|���������:\|�����:' \
> $tmp_file3
if [ -f $fact_file ]; then
	echo "*���������� ���� � ������:* _ $fact _" >> $tmp_file1
fi
printf "\n:black_small_square: <$CITY_URL|��������� �������> :black_small_square: <$INFO_URL|��� ���?>" >> $tmp_file1
cat $tmp_file3 \
| sed 's/+/%2B/' \
| sed 's/��������\s/:cloud: ��������/' \
| sed 's/��������, ��������� �����\s/:cloud: :umbrella: ��������, ��������� �����/' \
| sed 's/�������\s/:partly_sunny: �������/' \
| sed 's/�����������\s/:partly_sunny: �����������/' \
| sed 's/�����������, ��������� �����\s/:partly_sunny: :umbrella: �����������, ��������� �����/' \
| sed 's/�����������, �����\s/:partly_sunny: :zap: �����������, �����/' \
| sed 's/�������, ��������� �����\s/:partly_sunny: :umbrella: �������, ��������� �����/' \
| sed 's/����\s/:sunny: ����/' \
| sed 's/����, �����\s/:sunny: :partly_sunny: ����, �����/' \
> $tmp_file2
###
night="$(grep -A5 "����" $tmp_file2 | tail -5 | sed ':a;N;$!ba;s/\n/ /g')"
morning="$(grep -A5 "����" $tmp_file2 | tail -5 | sed ':a;N;$!ba;s/\n/ /g')"
day="$(grep -A5 "����" $tmp_file2 | tail -5 | sed ':a;N;$!ba;s/\n/ /g')"
even="$(grep -A5 "�����" $tmp_file2 | tail -5 | sed ':a;N;$!ba;s/\n/ /g')"
###
cat $tmp_file1 | sed 's/#NIGHT/'"$night"'/;s/#MORNING/'"$morning"'/;s/#DAY/'"$day"'/;s/#EVEN/'"$even"'/' > $tmp_file2
###
forecast="$(cat $tmp_file2)"
curl https://slack.com/api/chat.postMessage -X POST -d "channel=#${channel}" -d "text=${forecast}" -d "username=${username}" -d "token=${token}" -d "icon_url=http://${icon}" >/dev/null 2>&1
rm $tmpdir/forecast*.txt