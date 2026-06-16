# emacs-build/Makefile
# この Makefile は install.sh のサブコマンドへ委譲するだけの薄いラッパー。
.PHONY: help install uninstall reinstall

help:      ; @./install.sh help
install:   ; @./install.sh install
uninstall: ; @./install.sh uninstall
reinstall: ; @./install.sh reinstall
