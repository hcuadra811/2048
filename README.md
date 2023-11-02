## 2048 in Assembly Language

This is the famous game <a href="https://play2048.co/">2048</a> implemented in Turbo Assembler (TASM). Code is written in Spanish since I did it as a university project in Costa Rica - my bad about that; I mean, why else would anyone implement 2048 in assembly language lol

## How to play

In order to play the game you need to download <a href="https://www.dosbox.com/download.php?main=1">DOSBOX</a>. You can then download the 2048.exe under the bin folder. In order to execute, open DOSBOX and mount the drive using the path where you saved the 2048 exe file, for example:

```mount d C:/2048```

Then you navigate to the mounted drive:

```d:```

And then run the game:

```2048```

It should look like this:

![Screenshot of 2048 game in console.](https://raw.githubusercontent.com/hcuadra811/2048/master/screenshot.jpg)

You probably won't do this, but if you do, have fun!

## How to assemble and link

In the unlikely scenario that you want to assemble and link the source code yourself, then you need to download <a href="https://drive.google.com/file/d/1lsr8WZgvhrT73laZYukScWrJHrhhkJNp/view?usp=sharing">Turbo Assembly (TASM)</a>  

Just extract the zip wherever you prefer.

*FYI, you can also find TASM and TLINK online in case you don't download from here :)*

Now you may clone the repo or simply download the 2048.asm file, and place that file in the same folder as the TASM executables - putting the source code file in the same directory is not necessary but it will make this setup more straightforward. 

Once that is done, you may open DOSBOX and mount your drive. For example, if you're using Windows and your TASM folder is in C:/TASM, then you would run the following commands:

```mount d C:/TASM```

Then navigate to the mounted drive:

```d:```

Now you need to assemble the code:

```TASM 2048.asm```

Then link it:

```TLINK 2048.obj```

And finally you may play by just running:

```2048```

This will generate the same file that you can find under bin :)