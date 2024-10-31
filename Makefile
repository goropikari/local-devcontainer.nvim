setup:
	nvim --headless "+Lazy! sync" +qa

install:
	rm -rf ~/.local/neovim
	mkdir -p ~/.local/neovim
	mkdir -p ~/.local/bin
	cd ~/.local/neovim && \
	wget https://github.com/neovim/neovim/releases/download/v0.10.1/nvim.appimage && \
	chmod u+x nvim.appimage && \
	./nvim.appimage --appimage-extract && \
	ln -sf ${HOME}/.local/neovim/squashfs-root/usr/bin/nvim ${HOME}/.local/bin/nvim && \
	rm -f nvim.appimage

clean:
	rm -rf ~/.local/share/nvim
	rm -rf ~/.local/state/nvim

.PHONY: fmt
fmt:
	stylua -g '*.lua' -- .

.PHONY: lint
lint:
	typos -w

.PHONY: check
check: lint fmt
