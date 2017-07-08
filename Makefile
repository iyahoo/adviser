mac:
	cp ./scripts/notify-scripts/mac-terminal-notifier.sh notify.sh
	cp ./scripts/reading-scripts/mac-terminal-reader.sh reading.sh

linux:
	cp ./scripts/notify-scripts/linux-notify-send.sh notify.sh

check:
	gosh check.scm

clean:
	rm notify.sh
	rm reading.sh
