# emacs-build

emacs-plus(HomebrewのFormula) に ns-inline-patch を当ててビルドするためのビルドスクリプトです。

- [emacs-plus](https://github.com/d12frosted/homebrew-emacs-plus)
- [takaxp/ns-inline-patch](https://github.com/takaxp/ns-inline-patch)

emacs-plus の `build.yml`(Community Patches 方式)を使い、設定とパッチをこのリポジトリ内で完結させています。

## 使い方

```sh
git clone <this-repo>
cd emacs-build
./install.sh       # または: make install
```

## メンテナンス

```sh
make verify        # 現在の patches/ の SHA256 を表示
make fetch-patch   # 上流から最新パッチを取得し、新しい SHA256 を表示
make sha256        # SHA256 だけ表示
```

`make fetch-patch` でパッチを更新したら、表示された SHA256 を
`build.yml` と `install.sh` の `PATCH_SHA256` の両方に反映してください。
