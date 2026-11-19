# kariyon

公演サイトの公開フォルダを、予約した時刻で切り替える道具。仮サイトから本サイトへの切り替えなどに使う。

## 概要

- 制作者は、公開したい中身を `htdocs/` の下に**時刻の名前のフォルダ**で置く（sftp など）
- 毎分の cron から `bin/kariyon.rb` が走り、**時刻を過ぎたフォルダのうち、いちばん新しいもの**を公開先へつなぐ
- 先の時刻のフォルダは、その時刻が来るまで公開されない。切り替えたら通知のメールを送る

### フォルダの名前

`年月日時分` の 12 桁（`%Y%m%d%H%M`）。例: `202612010900` は 2026-12-01 09:00 に公開する。

```
htdocs/
  202611200000/   ← 仮サイト（公開中）
  202612010900/   ← 12/1 9:00 に切り替わる
```

- 時刻として読めない名前のフォルダは飛ばし、エラーとしてログに残す
- 時刻を過ぎたフォルダが 1 つも無いときは、いまの時刻の空のフォルダを作ってそれをつなぐ
- **公開をやめたいときは、空のフォルダを新しい時刻で置く**（kariyon を止める代わりになる）

### 公開先と、つなぎ方

サイト名は **clone したディレクトリの名前**で決まる（例: `www.example.jp`）。公開先は
`/usr/local/www/apache24/data/<サイト名>` で、設定 `mix` によってつなぎ方が変わる。

| `mix` | 公開先 | つなぎ方 |
| --- | --- | --- |
| `false`（既定） | `data/<サイト名>/` を kariyon が作る | `data/<サイト名>/www` を時刻のフォルダへのシンボリックリンクにする。`skel/` の中身（`.htaccess` など）をフォルダへ写す |
| `true` | 既存の `data/<サイト名>/www/`（ほかのアプリの公開フォルダ） | 時刻のフォルダの中身を 1 つずつ `www/` の中へリンクする（ドットファイルは混ざらない） |

張り替えるときは、kariyon が張ったリンクだけを消してから張り直す。公開先には目印の `.kariyon` が置かれる。

## 動かすのに要るもの

- **FreeBSD + Apache 2.4**（公開先 `/usr/local/www/apache24/data`・cron の置き場 `/usr/local/etc/cron.d` を前提にしている）
- **Ruby 3.3 以上**（`.ruby-version` は 3.4.9。CI は 3.3 と 3.4 で回している）と Bundler、git
- 通知は sendmail で送る（差出人は `root@<ホスト名>`）。宛先は設定の `mail.to`
- ログは syslog に出る。切り替えたときは予定の時刻からの遅れ（秒）を残し、60 秒を超えたら error にする

### 設定

`config/local.yaml`（追跡外）に書く。雛形は `config/local.sample.yaml`。

```yaml
mail:
  to: admin@example.com   # 切り替えの通知先
mix: true                 # 上の表を参照
well_known_dir: /usr/local/www/acme/.well-known   # 任意。証明書の確認用ディレクトリ
```

`well_known_dir` を書かないと、`rake install` の最後で公開先の置き場から確認用のディレクトリ
（`data/<別のディレクトリ>/www/.well-known`）を 1 つ探す。見つからない・複数あるときは落ちるので、指定するのが確実。

## デプロイ

### 構成管理で入れる

MINC の顧客サーバでは、構成管理（pooza/chubo-minc・非公開）の `kariyon` レシピで入れる。レシピは次の手で入れる手順と同じことをする。

- サイトのアカウントで clone し、宣言した版（タグ）を checkout する。`config/local.yaml` もレシピが書く
- gem は root で `bundle install` する
- `rake install` は、まだ入っていないサイトにだけ流す（`skel/.well-known` のリンクの有無で見る）
- 古い版（periodic で動いていたもの）で入れたサイトには `rake kariyon:cron:init` を 1 回流して、毎分の cron へ移す

### 手で入れる

1. サイトのアカウントで、サイト名のディレクトリへ clone する

   ```sh
   git clone https://github.com/pooza/kariyon.git ~/kariyons/www.example.jp
   cd ~/kariyons/www.example.jp
   ```

2. `config/local.yaml` を書く（上の「設定」）
3. `bundle install`
4. `bundle exec rake install`（初回だけ。下の注意）
   - `kariyon:cron:init` … `/usr/local/etc/cron.d/kariyon-<サイト名の . を - に>` に毎分の 1 行を置く（root で流れる）。古い periodic のリンクがあれば消す
   - `kariyon:htdocs:init` … 公開先を作り直し、いまの時刻のフォルダをつなぐ
   - `kariyon:skel:well_known_dir` … `skel/.well-known` を確認用のディレクトリへリンクする

サイトのアカウントが、公開先の置き場と `/usr/local/etc/cron.d` に書けること。FreeBSD には `/usr/local/etc/cron.d` が既定で無いので、先に作っておく。

> ⚠ **`rake install` は初回だけ流す。**`kariyon:htdocs:init` は clean → create の順で、`mix: false` の clean は
> **公開先 `data/<サイト名>` を `rm_rf` してから作り直す。**更新のたびに流すと、公開先に置いたものが消える。
> 版を上げるときは checkout と `bundle install` だけにする（`htdocs/` と `config/local.yaml` は追跡外なので残る）。
> `rake uninstall` も同じ clean を流す。

切り替えをすぐ確かめたいときは `bundle exec rake kariyon:htdocs:update`（cron が流すものと同じ）。

## 開発

```sh
bundle install
bundle exec rubocop
bundle exec rake test   # test/ はまだ無い
```

CI（`.github/workflows/test.yml`）は push のたびに Ruby 3.3 と 3.4 で、pooza/ginseng-style の手順（rubocop など）を回す。

## ライセンス

[LICENSE.txt](LICENSE.txt)
