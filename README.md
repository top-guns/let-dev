# alias-gun
alias engine for bush/zsh

## Installation

```bash
(cd ~ && git clone git@github.com:top-guns/alias-gun.git)
mv ~/alias-gun ~/.alias-gun

cp ~/.alias-gun/default.env ~/.alias-gun/.env

mkdir ~/aliases

echo '' >> ~/.bashrc
echo '# Add alias-gun aliases' >> ~/.bashrc
echo '[ -d ~/.alias-gun ] && source ~/.alias-gun/create-aliases' >> ~/.bashrc

source ~/.alias-gun/create-aliases
```