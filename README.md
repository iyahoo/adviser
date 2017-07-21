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

### 注意

現在 (2017/7/21) brew 版の terminal-notifier が通知に失敗します (https://github.com/julienXX/terminal-notifier/issues/222).

https://github.com/julienXX/terminal-notifier/releases から最新版を直接ダウンロードして path の通った場所に置いて下さい。

## Gitemoji

https://github.com/iyahoo/adviser/commit/dbe0d9758ab90d58461e0d6682477c36012e5d32 のコミットから https://github.com/carloscuesta/gitmoji を参考に emoji の統一を心がけるようにしました。
