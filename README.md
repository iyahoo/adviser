# Adviser

## Installation

https://github.com/shirok/Gauche をインストールする必要があります。  
http://practical-scheme.net/gauche/download-j.html を参考にするか各 OS のパッケージ管理システムを利用してください。  

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

`notify-scripts`に mac や linux 向けのサンプルを用意しています。

`make mac` または `make linux` でコマンドに応じたスクリプトを `notify-scripts` フォルダから展開します。自分の環境に合わせて選択してください。

## Gitemoji

https://github.com/iyahoo/adviser/commit/dbe0d9758ab90d58461e0d6682477c36012e5d32 のコミットから https://github.com/carloscuesta/gitmoji を参考に emoji の統一を心がけるようにしました。
