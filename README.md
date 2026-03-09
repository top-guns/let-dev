# let-dev
command engine for bush/zsh

## Installation

```bash
(cd ~ && git clone git@github.com:top-guns/let-dev.git)
source ~/let-dev/install.sh
```

Optional: Install with specific profile and shell:

```bash
source ~/let-dev/install.sh --shell=zsh --profile=myprofile --no-update
```

## Using

 * Put your offen used scripts to the **~/let-dev/profiles/<your profile>/** folder.
 * You can use hierarhical structure of script folders.
 * All scripts from the **~/let-dev/profiles/<your profile>/** folder will appear as aliases with **:** as prefix and delimiter.
 * You can use command **:** to list your aliases.
 * You can run let-dev shell with **::** command
