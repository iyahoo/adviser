mac:
	cp ./notify-scripts/mac-terminal-notifier.sh notify.sh
	cp ./reading-scripts/mac-terminal-reader.sh reading.sh

linux:
	cp ./notify-scripts/linux-notify-send.sh notify.sh

clean:
	rm notify.sh
	rm reading.sh
