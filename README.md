# Synapse Termux
A script and a guide on how to host matrix using synapse and nginx on termux.  
You can choose to follow along the [GUIDE.md](/GUIDE.md), or to just curl the script to bash and execute it to automatically have what you need.

## Pre-requisites
* A phone (preferly broken to repurpose it to be your homeserver)
* And internet connection
* A router with the ability to do port forwarding
* Some paitience

## Why the guide if there's a script ?
Well, this is an experiment, being done for educational purposes. But when you need it again, it's borring to have to follow a guide. The guide is for the DIY people who are interested in this. And even those people might need the script as the process of copy pasting might not be interesting.

## Some advices that aren't mentioned in the guide!
The guide does exactly the same as the script does, But with some explination to why everything is the way it is. Both the script and the guide were just an improvised way of copying the instruction from the official sources and trying to bend them to the rough android environment (same as everything else under termux).  

**If you intend to really use this as your matrix server Please consider the following**
* This is completely experimental. I can't be held responsible for any data loss to your precisous messages (all the programs being used do not have warrenty as well so. You're on your own mate).
* Consider disabling every app that you're not using (You can use `adb` to disable even google apps and any other, just make sure to enable them if you ever had to reboot your phone) This will help you obtain more resources for your server.
```shell
# To disable google apps for example
for app in $(adb shell pm list packages | cut -d: -f2 | grep google); do
	adb shell pm disable-user --user 0 "$app"
done
```
To re-enable everything.
```shell
for app in $(adb shell pm list packages -d); do
	adb shell pm enable --user 0 "$app"
done
```
Please note that even if you disable everything (don't do it, it's dangerous), this won't be enough for you to enter rooms with a big number of people as self hosting synapse requires a lot of computer power which a phone simply cannot provide. This is just to help a bit.
* If your phone has a broken screen and you're doing this to repurpose it, or you're following the guide and want to do this from your computer. You can use tools like `scrcpy` to start sshd from termux (it is recommended to enable it as a service using `termux-services` since you're gonna `ssh` into your server often.)

## Progress
- [X] Installation and configuration of matrix-synapse
- [X] Installation and configuration of nginx
- [X] Installation and configuration of certbot
