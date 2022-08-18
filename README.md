# Synapse Termux
A script and a guide on how to host matrix using synapse and nginx on termux.  
You can choose to follow along the [GUIDE.md](/GUIDE.md), or to just curl the script to bash and execute it to automatically have what you need.

This repo was chosen as the [dept of guides in This Week In Matrix](https://matrix.org/blog/2022/08/05/this-week-in-matrix-2022-08-05/#dept-of-guides-%F0%9F%A7%AD) on the 5th of Auguest 2022.

For steps on how to do this using dendrite instead of synapse (recommended for better performance), check out [starchturrets/dendrite-termux-experiment](https://github.com/starchturrets/dendrite-termux-experiment/)

## Pre-requisites
* A phone (preferably broken to repurpose it to be your home server)
* And internet connection
* A router with the ability to do port forwarding
* Some patience

## Why the guide if there's a script ?
Well, this is an experiment, being done for educational purposes. But when you require it again, it's boring to have to follow a guide. The guide is for the DIY people who are interested in this. And even those people might need the script as the process of copying and pasting might not be interesting.

## Some advice that isn't mentioned in the guide!
The guide does exactly the same as the script does, But with some explanation to why everything is the way it is. Both the script and the guide were just an improvised way of copying the instruction from the official sources and trying to bend them to the rough android environment (same as everything else under termux).  

**If you intend to really use this as your matrix server Please consider the following**
* This is completely experimental. I can't be held responsible for any data loss to your precious messages (all the programs used do not have warranty as well so. You're on your own mate.
* Consider disabling apps that you're not using. You can use `adb` to do this, just make sure to enable them if you ever have to reboot your phone, This will help you obtain more resources for your server.
```shell
# To disable google apps for example
for app in $(adb shell pm list packages | cut -d: -f2 | grep google); do
	adb shell pm disable-user --user 0 "$app"
done
```
To re-enable everything.
```shell
for app in $(adb shell pm list packages -d | cut -d: -f2); do
	adb shell pm enable --user 0 "$app"
done
```
Please note, even if you disable all apps on your phone (don't do it, it's dangerous). This won't be enough for you to enter larger rooms with many people, as self-hosting synapse requires a lot of computer power which a phone simply cannot provide.
* If your phone has a broken screen, and you're doing this to repurpose it, or you're following the guide and want to do this from your computer. You can use tools like `scrcpy` to start sshd from termux (it is recommended to enable it as a service using `termux-services` since you're gonna `ssh` into your server often.)

## Progress
- [X] Documenting the installation and configuration of matrix-synapse
- [X] Documenting the installation and configuration of nginx
- [X] Documenting the installation and configuration of certbot
- [X] Automating the installation and configuration of matrix-synapse
- [X] Automating the installation and configuration of nginx
- [X] Automating the installation and configuration of certbot
- [X] Add `Usage` after installation is complete in GUIDE.md
- [ ] Add `Usage` for the script in README
