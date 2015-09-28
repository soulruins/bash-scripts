#!/bin/bash

#set -x
# Домашнаяя страница: https://github.com/soulruins/bash-scripts/tree/master/slack-bots
# Пример использования:
# ./weather_slack.sh "general" "today" "Погода на СЕГОДНЯ"
# ./weather_slack.sh "general" "tommorow" "Погода на ЗАВТРА"
token="<your_api>" #укажите свой API-ключ https://api.slack.com/web
city_code="4368" # код города, по умолчанию - Москва (4368)
INFO_URL="https://slack-files.com" # ваша информация о боте (ссылка)
fact_file="/home/weather_facts.txt" # местоположение файла с фактами о погоде, если они нужны (каждый факт с новой строки, требует утилиты randomize-lines)
###
channel="$1" # имя канала, указывается первым параметром при запуске скрипта
username="$3" # имя бота, указывается третьим параметром при запуске скрипта
#icon=":weather:"
### лучше не менять
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
### приступим
echo "*Текущие погодные условия*" > $tmp_file1
CITY_URL="https://www.gismeteo.ru/city/daily/$city_code/"
curl $CITY_URL 2>/dev/null \
| sed -nre '/section higher/,/мм рт. ст./p' \
| sed -r 's/(.*)class="png" title="(.*)" style="background-image: url\(\/\/(.*)\)"><br \/><\/dt>/> Иконка: \3/' \
| sed -r '/section higher|cloudness|wicon wind|crumb|scity|\/div|value m_temp f|m_wind mih|m_wind kmh|\/dl|class="temp|wicon barp|dt/d' \
| sed 's/+/%2B/' \
| sed -r 's/(.*)class="type(.*)>(.*)<\/h2>/> Город: \3/' \
| sed -r 's/(.*)<dd(.*)td>(.*)<\/td(.*)\/dd>/> Погода: \3/' \
| sed -r 's/(.*)<dd class=(.*)>(.*)<span class="meas(.*)span><\/dd>/> Температура воздуха: *\3 C*/' \
| sed -r 's/(.*)value m_wind ms(.*)>(.*)<span class="unit">(.*)<\/span><\/dd>/> Ветер: \3 \4/' \
| sed -r 's/(.*)value m_press torr(.*)>(.*)<(.*)>(.*)<\/span><\/dd>/> Давление: \3 \5/' \
>> $tmp_file1
icon="$(cat $tmp_file1 | grep "Иконка:" | sed -r 's/> Иконка:\s(.*)/\1/')"
sed -i '3d' $tmp_file1
echo "*$username*" >> $tmp_file1
printf "> *Прогноз на ночь*\n#NIGHT\n" >> $tmp_file1
printf "> *Прогноз на утро*\n#MORNING\n" >> $tmp_file1
printf "> *Прогноз на день*\n#DAY\n" >> $tmp_file1
printf "> *Прогноз на вечер*\n#EVEN\n" >> $tmp_file1
curl $CITY_URL 2>/dev/null \
| sed -nre "/$firstday/,/$lastday/p" \
| sed -r '/clicon/d' \
| sed -r 's/(.*)Ночь(.*)<\/th>/> *Прогноз на ночь*/' \
| sed -r 's/(.*)Утро(.*)<\/th>/> *Прогноз на утро*/' \
| sed -r 's/(.*)День(.*)<\/th>/> *Прогноз на день*/' \
| sed -r 's/(.*)Вечер(.*)<\/th>/> *Прогноз на вечер*/' \
| sed -r 's/(.*)class="cltext">(.*)<\/td>/> \2 :white_small_square:/' \
| sed -r 's/(.*)<td class="temp"><span class=(.*)>(.*)<\/span><span class=(.*)>(.*)<\/span><\/td>/*\3 C* :white_small_square:/' \
| sed -r 's/(.*)<td><span class=(.*)m_press(.*)>(.*)<\/span><span class=(.*)m_press(.*)>(.*)<\/span><span class=(.*)m_press(.*)>(.*)<\/span><\/td>/Давление: \4 мм рт. ст. :white_small_square:/' \
| sed -r 's/(.*)<td><dl class="wind"><dt class=(.*) title="(.*)">(.*)<\/dt><dd><span class=(.*)m_wind(.*)>(.*)<\/span><span class=(.*)m_wind(.*)>(.*)<\/span><span class=(.*)m_wind(.*)>(.*)<\/span><\/dd><\/dl><\/td>/Ветер: \3, \7 м%2Fс :white_small_square:/' \
| sed -r 's/(.*)<td>([0-9]{2})<\/td>/Влажность: \2%/' \
| grep 'Прогноз на\|Подробнее:\|:white_small_square:\|Давление:\|Влажность:\|Ветер:' \
> $tmp_file3
if [ -f $fact_file ]; then
	echo "*Интересный факт о погоде:* _ $fact _" >> $tmp_file1
fi
printf "\n:black_small_square: <$CITY_URL|Подробный прогноз> :black_small_square: <$INFO_URL|Что это?>" >> $tmp_file1
cat $tmp_file3 \
| sed 's/+/%2B/' \
| sed '/\Sасмурно/{s/^>/> :cloud:/}' \
| sed '/\Sблачно\|\Sалооблачно\|\Sымка/{s/^>/> :partly_sunny:/}' \
| sed '/\Sсно/{s/^>/> :sunny:/}' \
| sed '/\Sнег/{s/^>/> :snowflake:/}' \
| sed '/\Sождь\|\Sивень/{s/^>/> :umbrella:/}' \
| sed '/\Sроза/{s/^>/> :zap:/}' \
> $tmp_file2
###
night="$(grep -A5 "ночь" $tmp_file2 | tail -5 | sed ':a;N;$!ba;s/\n/ /g')"
morning="$(grep -A5 "утро" $tmp_file2 | tail -5 | sed ':a;N;$!ba;s/\n/ /g')"
day="$(grep -A5 "день" $tmp_file2 | tail -5 | sed ':a;N;$!ba;s/\n/ /g')"
even="$(grep -A5 "вечер" $tmp_file2 | tail -5 | sed ':a;N;$!ba;s/\n/ /g')"
###
cat $tmp_file1 | sed 's/#NIGHT/'"$night"'/;s/#MORNING/'"$morning"'/;s/#DAY/'"$day"'/;s/#EVEN/'"$even"'/' > $tmp_file2
###
forecast="$(cat $tmp_file2)"
curl https://slack.com/api/chat.postMessage -X POST -d "channel=#${channel}" -d "text=${forecast}" -d "username=${username}" -d "token=${token}" -d "icon_url=http://${icon}" >/dev/null 2>&1
rm $tmpdir/forecast*.txt
