### Bash aliases ###

# Package managers
alias pacinstall="sudo pacman -S"
alias install="paru -S"
alias update="paru -Syu --noconfirm && sudo flatpak update -y"
alias uninstall="paru -Rsc --noconfirm"
alias search="parui"
alias pacman="/usr/bin/octopi"
#alias reinstall="pamac reinstall"
#alias info="pamac info"

# File managers
alias ..="cd .."
alias ls="exa --icons -la"
alias cat="bat --style=auto"

# Lunarvim text editor
#alias nvim="editar"

# ASDF shortcut
alias lang="asdf"
