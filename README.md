# simple-appimage-thumbnailer
Simple AppImage thumbnailer in POSIX shell.

To install simply run:

```
git clone https://github.com/Samueru-sama/simple-appimage-thumbnailer.git
cd simple-appimage-thumbnailer
chmod +x ./install.sh
./install.sh
```

Run `./install.sh uninstall` to uninstall the thumbnailer. 

# Known issues

* It doesn't work with thunar for some reason, it works perfectly with both `caja` and `pcmanfm-qt` but not with thunar, what's weird is that if I let caja generate the thumbnails they will be displayed in thunar as well, but thunar can't generate them. 
