#!/usr/bin/env bash

if ! which curl 1>/dev/null
  then
    if (zenity --question --text="Для выполнения операции требуется установить пакет curl. Установить?" --width=300)
      then
	      if [[ "$USER" != 'root' ]]; then
					OUTPUT=$(zenity --forms --title="Установка curl" --text="Введите пароль root" --separator="," --add-password="")
					accepted=$?
					if [ $accepted = 0 ]; then
						PASSWORD=$(awk -F, '{print $1}' <<<$OUTPUT)
						echo $PASSWORD | sudo -S bash -c "apt-get install curl -y"
						zenity --info --width=300 --text "Пакет curl установлен"
					else
						exit
					fi
				fi
		else
			exit
		fi
fi

if [[ ! -e ~/.config/ ]]; then
	zenity --warning --text="Похоже, вы используете эту программу установки в системе отличной от Ubuntu"  --title="Ошибка"
	exit
fi

# Установка директории
# ====================
username=$(whoami)
CONFIG_DIR='~/.config/screencloud/'
IS_SNAP=false


# Проверяем на SNAP
if [[ ! -e $CONFIG_DIR ]]; then
	IS_SNAP=true
	CONFIG_DIR='/home/'$username'/snap/screencloud/current/.config/screencloud'
fi

echo ${CONFIG_DIR};

if [[ ! -e $CONFIG_DIR ]]; then
	zenity --warning --text="Похоже, ScreenCloud не установлен. Установите программу и запустите этот скрипт повторно."  --title="Ошибка"
	exit
else
	CONFIG_FILE=${CONFIG_DIR}'/ScreenCloud.conf'
fi

# ПОЛУЧЕНИЕ ТОКЕНА
# ================
zenity --info --width=500 --text "Для загрузки файлов на w6p.ru у вас должен быть активирован модуль Shell Script.
Включить его нужно в настройках программы:
Preferences > вкладка Online Services > More services > раздел Local"

OUTPUT=$(zenity --forms --title="Токен" --text="Введите токен" --separator="," --add-entry="")
accepted=$?
	if [ $accepted = 0 ]; then
		TOKEN=$(awk -F, '{print $1}' <<<$OUTPUT)
	else
		exit
	fi

# УСТАНОВКА КОНФИГА
# =================
find=$(grep -c uploaders $CONFIG_FILE)
find2=$(grep -c shell $CONFIG_FILE)
if [[ $find != 0 ]]; then
	if [[ $find2 != 0 ]]; then
		sed -i '/shell\\command/c shell\\command='$CONFIG_DIR'/upload.sh {s} '$TOKEN'' $CONFIG_FILE
		sed -i '/shell\\copyOutput/c shell\\copyOutput=True' $CONFIG_FILE
	else
		echo "shell\\command=$CONFIG_DIR/upload.sh {s} $TOKEN
shell\\copyOutput=True" >> $CONFIG_FILE
	fi
else
	echo "
[uploaders]
shell\\command=$CONFIG_DIR/upload.sh {s} $TOKEN
shell\\copyOutput=True" >> $CONFIG_FILE
fi


# СОЗДАНИЕ ЗАГРУЗЧИКА
# ===================

# В случае со snap там может быть не правильный путь к изображению
# Передаваемый путь /tmp/image.jpg
# Фактический путь /tmp/snap.screencloud/tmp/image.jpg
# @todo Проблема! /tmp/snap.screencloud/ создается каждый раз при старте системы заново =((
CHANGE_PATH=''
if [ $IS_SNAP = true ]; then
	sudo chmod o+x /tmp/snap.screencloud/ # без этого не будет доступа к чтению файла
	CHANGE_PATH='IMAGE_PATH=${IMAGE_PATH/tmp/tmp/snap.screencloud/tmp} # замена пути для snap'
fi

echo '#!/usr/bin/env bash
IMAGE_PATH=$1
'$CHANGE_PATH'
# echo $IMAGE_PATH >> /home/north/test/log.txt # @todo удалить

curl -F "token=$2" -F "UploadForm[imageFile]=@$IMAGE_PATH" https://w6p.ru/site/upload' > $CONFIG_DIR/upload.sh

chmod +x $CONFIG_DIR/upload.sh


# уведомление
zenity --info --width=400 --text "Программа ScreenCloud успешно настроена для загрузки файлов на w6p.ru
После создания скриншота выберите для сохранения Shell Script (поле Save to)"
exit
