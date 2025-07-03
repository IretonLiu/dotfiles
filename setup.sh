
if [ -d "$HOME/.config/hypr" ]; then
       rm -rf $HOME/.config/hypr
fi       
ln -sn $HOME/dotfiles/hypr $HOME/.config
ln -sn $HOME/dotfiles/waybar $HOME/.config
ln -sn $HOME/dotfiles/rofi $HOME/.config

git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
ln -sn $HOME/dotfiles/tmux $HOME/.config

git clone --depth 1 https://github.com/wbthomason/packer.nvim ~/.local/share/nvim/site/pack/packer/start/packer.nvim
ln -sn $HOME/dotfiles/nvim $HOME/.config

ln -sn $HOME/dotfiles/alacritty $HOME/.config

ln -sn $HOME/dotfiles/.zshrc $HOME
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
