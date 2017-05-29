# Adviser

## Installation

https://github.com/shirok/Gauche をインストールする必要があります。  
http://practical-scheme.net/gauche/download-j.html を参考にするかパッケージ管理システムを利用してください。  

```sh
$ git clone https://github.com/iyahoo/adviser.git
$ cd adviser
$ gosh main.scm
```

また https://github.com/hanslub42/rlwrap を使用するのがお勧めです。  

```sh
$ rlwrap gosh main.scm
```

## 通知

作業終了後などに通知を行う事ができます。

main.scmと同じディレクトリに`notify.sh`という実行可能なシェルスクリプトがあると、第一引数に通知メッセージを渡して実行します。

`notify-scripts`にmacやlinux向けのサンプルを用意しています。
