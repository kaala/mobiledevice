#mobiledevice

**Massive Apple Device Configuration CLI Utility**

Apple Configurator alternative


#Manual

Use together with shell script

**devices**
```
#List all connected devices
mobiledevice devices
```

**deploy**
```
#Massive device deploy
mobiledevice deploy config
                    ^deploy config
```

**install**
```
#install application on certain device
mobiledevice install xxx.ipa [-udid xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx]
                     ^ipa file      ^udid (no udid means first connected device)
```

**uninstall**
```
#uninstall application on certain device
mobiledevice uninstall xx.xxx.xxxx [-udid xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx]
                       ^app id            ^udid
```

**list**
```
#list application on certain device
mobiledevice list [-udid xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx]
                         ^udid
```

**mc_install**
```
#install mobileconfig on certain device
mobiledevice mc_install xxx.mobileconfig -udid xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                        ^mobileconfig          ^udid
```

**mc_uninstall**
```
#uninstall mobileconfig on certain device
mobiledevice mc_uninstall xx.xxx.xxxx -udid xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                          ^config id        ^udid
```

**mc_list**
```
#list mobileconfig on certain device
mobiledevice mc_list -udid xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
                           ^udid
```

**sleep**
```
#wait a few seconds between commands, useful in deploy mode
mobiledevice sleep 5
                   ^seconds
```


#Deploy Mode


Example of a deploy config file

```
uninstall xx.xxx.xxxx
install xxx.ipa
mc_install xxx.mobileconfig
sleep 10
```


#Website

[http://wettags.com](http://wettags.com/donate)

