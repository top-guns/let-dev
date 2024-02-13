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
echo "[ -d '$HOME/.alias-gun' ] && source '$HOME/.alias-gun/create-aliases'" >> ~/.bashrc

source ~/.alias-gun/create-aliases
```

## Using

 * Put your offen used scripts to the **~/aliases** folder.
 * You can use hierarhical structure of script folders.
 * All scripts from the **~/aliases** folder will appear as aliases with **:** as prefix and delimiter.
 * You can use command **:** to list your aliases.
