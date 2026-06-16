# emacs-build

emacs-plus(HomebrewのFormula) に ns-inline-patch を当ててビルドするためのEmacsビルドスクリプトです。

- [emacs-plus](https://github.com/d12frosted/homebrew-emacs-plus)
- [takaxp/ns-inline-patch](https://github.com/takaxp/ns-inline-patch)

emacs-plus の `build.yml`([Community Patches 方式](https://github.com/d12frosted/homebrew-emacs-plus#community-features))を使います。
パッチは `build.yml` に 本体 URL と SHA256 を記述し、ビルド時に formula が取得・検証して適用します。

## 前提

- macOS
- Homebrew

## 使い方

```sh
git clone git@github.com:kazootkr/emacs-build.git
cd emacs-build
./install.sh       # または make install
```

## 現在のバージョン

- Emacs 30.x
- emacs-29.1-inline.patch

## インストール対象のEmacs/patchバージョンの切り替え方法

| 対象 | 編集する場所 | 補足 |
|---|---|---|
| Emacs のバージョンを切り替える(例: @30 → @31) | `install.sh` の `FORMULA`(1 行) | `emacs-plus@31` に変えるだけ。Makefile / build.yml の変更は不要 |
| パッチを切り替える・更新する | `build.yml` の `url` と `sha256` | 新しい SHA256 は下記で取得して反映 |

パッチ更新時の SHA256 取得:

```sh
curl -fsSL <build.yml の url> | shasum -a 256
```
