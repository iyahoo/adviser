#!/bin/sh

# terminal-notifier (https://github.com/julienXX/terminal-notifier) を利用してデスクトップに通知します。
# $ brew install terminal-notifier でインストールできます。
# https://github.com/julienXX/terminal-notifier/blob/master/README.markdown にある通り通知設定をすることを推奨します (Action が使えないとすぐに通知が消えてしまい見逃すため)。

terminal-notifier -message "$1" -closeLabel Close
