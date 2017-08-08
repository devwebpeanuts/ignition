EUID := $(shell id -u -r)
HOSTNAME := $(shell hostname)

apt-install = apt-get install -y $1
pip-install = pip install --user $1
pip-upgrade = pip install --upgrade pip
change-owner = chown -R $(SUDO_USER). $1

.PHONY: check ignite tools tmux powerline python-pip fonts restore-permissions rocknroll github dotfiles

all: check ignite

check:
ifneq ($(EUID),0)
	@echo Please run as root user
	@exit 1
endif

ifndef USERMAIL
	@echo Missing USERMAIL
	@exit 1
endif

ifndef GITHUB_USERNAME
	@echo Missing USERNAME
	@exit 1
endif

ignite: check apt-update tools tmux powerline restore-permissions github dotfiles rocknroll

apt-update:
	@apt-get update

tools:
	@$(call apt-install, wget curl vim)

tmux:
	@$(call apt-install, tmux)

powerline: python-pip fonts
	@$(call pip-install, powerline-status)
	@$(call pip-install, powerline-gitstatus)

python-pip:
	@$(call apt-install, python-pip)
	@$(call pip-upgrade,)

fonts:
	@if [ -d /usr/share/fonts/powerline-fonts ]; then rm -rf /usr/share/fonts/powerline-fonts; fi
	@cd ~; \
	wget https://github.com/Lokaltog/powerline/raw/develop/font/PowerlineSymbols.otf; \
	mv PowerlineSymbols.otf /usr/share/fonts/; \
	wget https://github.com/Lokaltog/powerline/raw/develop/font/10-powerline-symbols.conf; \
	mv 10-powerline-symbols.conf /etc/fonts/conf.d/; \
	fc-cache -vf; \
	git clone https://github.com/Lokaltog/powerline-fonts.git; \
	mv ~/powerline-fonts /usr/share/fonts/; \
	fc-cache -vf

restore-permissions:
	@$(call change-owner, ~/.local)

openssh:
	@$(call apt-install, openssh-client)

github: openssh
	@su $(SUDO_USER) --preserve-environment -c 'ssh-keygen -t rsa -b 4096 -C "$(USERMAIL)"'
	@echo Adding SSH key to github account...
	@curl -u "$(GITHUB_USERNAME)" \
    	--data "{\"title\":\"$(HOSTNAME)_`date +%Y%m%d%H%M%S`\",\"key\":\"`cat ~/.ssh/id_rsa.pub`\"}" \
    	https://api.github.com/user/keys

dotfiles:
	@if [ -d ~/.dotfiles ]; then rm -rf ~/.dotfiles; fi
	@su $(SUDO_USER) --preserve-environment -c 'git clone git@github.com:devwebpeanuts/dotfiles.git ~/.dotfiles'
	@cd ~/.dotfiles; \
	su $(SUDO_USER) ./setup.sh

rocknroll:
	@echo
	@echo
	@echo "Now you have to run 'source ~/.bashrc'"
	@echo
	@echo "That's it! \m/ Rock'n'Roll \m/"

