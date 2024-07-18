# Visdir - stylish visualisation of directories and its contents

Visdir is a CLI tool written in bash to visualize a directory and its contents in an aesthetically pleasing manner.  

It was developed as a tool to assist in developing a short 'How does git work' writeup for peers. However, I figured I would also release the tool standalone. If you want to checkout the short visual walktrough, see [[this repo]]

## Example

```text
user@machine-name:~/mydir$ visdir
├── file1.cs
│       >> Console.WriteLine("Hello World!");
├── file2.cs
│       >> int a = 1;
│       >> int b = 2;
│       >> Console.WriteLine($"a + b = {a + b}");
└── subdir
        └── bigfile.cs
                >> void greet(string user) {
                >>     string welcometext = "Hello, ";
                >>     Console.WriteLine(welcometext + user);
                >> }
                >>
                >> greet("Bob");
```

## Installation

Installation of visdir is easy, and only requires a couple of commands.

```sh
# clone the visdir github repository
git clone https://github.com/TheMarteh/visdir-cli

# give executable permissions to the script file
sudo chmod +x ./visdir

# OPTION 1: Install visdir for all users on this machine
# add the file to your /usr/local/bin folder so the command is 
# available for all users. This folder will most likely already be in your PATH
cp visdir usr/local/bin/visdir


# OPTION 2: Install visdir for the current user only
# If it doesn't yet exists, create a bin folder in the home directory
if [[ -d "$HOME/bin" ]]; then
    # folder already exists. it *probably* is already added to the PATH as well
    echo "$HOME/bin already exists"
else
    # create the folder
    mkdir "$HOME/bin"

    # add this folder to the PATH
    export PATH="$HOME/bin:$PATH"
fi

# copy the script to the ~/bin directory
cp visdir $HOME/bin/visdir
```
