//
//  MobileDevice.m
//  mobiledevice
//
//  Created by huangyi on 15/8/31.
//  Copyright (c) 2015年 wettags. All rights reserved.
//

#import "MobileDevice.h"

#include <sys/socket.h>
#import "CoreFoundation.h"
#import "AMDevice.h"


const NSString *SVC_INSTALLATION_PROXY = @"com.apple.mobile.installation_proxy";
const NSString *SVC_MCINSTALL = @"com.apple.mobile.MCInstall";
const NSString *SVC_DIAGNOSTICS_RELAY = @"com.apple.mobile.diagnostics_relay";
const NSString *SVC_MISAGENT = @"com.apple.misagent";

const NSString *ProfileMetadata = @"ProfileMetadata";
const NSString *OrderedIdentifiers = @"OrderedIdentifiers";
const NSString *PayloadDisplayName = @"PayloadDisplayName";
const NSString *PayloadOrganization = @"PayloadOrganization";
const NSString *PayloadIdentifier = @"PayloadIdentifier";

const NSString *CFBundleIdentifier = @"CFBundleIdentifier";
const NSString *ApplicationType = @"ApplicationType";
const NSString *CFBundleName = @"CFBundleName";
const NSString *CFBundleDisplayName = @"CFBundleDisplayName";
const NSString *CFBundleShortVersionString = @"CFBundleShortVersionString";
const NSString *CFBundleVersion = @"CFBundleVersion";


BOOL Connect(AMDevice *device){
    return AMDeviceConnect(device.device)==MDERR_OK;
}
BOOL Disconnect(AMDevice *device){
    return AMDeviceDisconnect(device.device)==MDERR_OK;
}
BOOL ValidatePairing(AMDevice *device){
    if (AMDeviceIsPaired(device.device)!=0) {
        return AMDeviceValidatePairing(device.device)==MDERR_OK;
    }else{
        return AMDevicePair(device.device)==MDERR_OK;
    }
}
BOOL StartSession(AMDevice *device){
    return AMDeviceStartSession(device.device)==MDERR_OK;
}
BOOL StopSession(AMDevice *device){
    return AMDeviceStopSession(device.device)==MDERR_OK;
}
BOOL StartService(AMDevice *device,NSString *service){
    CFStringRef svc=(__bridge CFStringRef)(service);
    int socket=0;
    BOOL success=AMDeviceStartService(device.device, svc, &socket)==MDERR_OK;
    device.socket_fd=socket;
    return success;
}

NSData *SocketIO(AMDevice *device,NSData *source){
    int sock=device.socket_fd;
    CFDataRef messageAsXML = (__bridge CFDataRef)(source);

    CFIndex xmlLength = CFDataGetLength(messageAsXML);
    uint32_t sz;
    sz = htonl(xmlLength);
    send(sock, &sz, sizeof(sz), 0);
    send(sock, CFDataGetBytePtr(messageAsXML), xmlLength, 0);

    recv(sock, &sz, sizeof(sz), 0);
    sz = ntohl(sz);
    unsigned char *buff = malloc(sz);
    unsigned char *p = buff;
    recv(sock, p, sz, 0);

    NSData *dest = [NSData dataWithBytes:buff length:sz];
    free(buff);

    return dest;
}


NSDictionary* LookupApps(AMDevice *device){
    CFDictionaryRef apps=NULL;
    AMDeviceLookupApplications(device.device, 0, &apps);
    NSDictionary *dict=(__bridge NSDictionary *)(apps);
    return dict;
}
BOOL InstallApp(AMDevice *device,NSString *appPath){
    NSURL *url=[NSURL fileURLWithPath:appPath];
    CFURLRef appUrl=(__bridge CFURLRef)(url);
    NSDictionary *dict=@{ @"PackageType":@"Developer" };
    CFDictionaryRef opts=(__bridge CFDictionaryRef)(dict);
    BOOL copy=AMDeviceSecureTransferPath(0, device.device, appUrl, opts, NULL, 0)==MDERR_OK;
    if (!copy) {
        return false;
    }
    return AMDeviceSecureInstallApplication(0, device.device, appUrl, opts, NULL, 0)==MDERR_OK;
}
BOOL UninstallApp(AMDevice *device,NSString *appId){
    CFStringRef bundleId=(__bridge CFStringRef)(appId);
    return AMDeviceSecureUninstallApplication(0, device.device, bundleId, 0, NULL, 0)==MDERR_OK;
}

void ShowApps(NSDictionary *apps){
    for (NSString *key in apps) {
        NSDictionary *app=apps[key];
        NSString *appId=app[CFBundleIdentifier];
        NSString *appType=app[ApplicationType];
        NSString *appName=app[CFBundleName];
        NSString *version=app[CFBundleShortVersionString];
        NSString *build=app[CFBundleVersion];
        NSString *line=[NSString stringWithFormat:@"%@\t%@\t%@ %@(%@)",appId,appType,appName,version,build];
        WriteLine(line);
    }
}
void ShowProfiles(NSDictionary *profiles){
    for (NSString *key in profiles) {
        NSDictionary *profile=profiles[key];
        NSString *profileId=key;
        NSString *profileName=profile[PayloadDisplayName];
        NSString *profileOrganization=profile[PayloadOrganization];
        NSString *line=[NSString stringWithFormat:@"%@\t%@(%@)",profileId,profileName,profileOrganization];
        WriteLine(line);
    }
}


extern BOOL OnDeviceAttached(AMDevice *device);

static void usbMuxMode(struct am_device_notification_callback_info *info,int cookie){
    struct am_device *dev=info->dev;

    if (!dev) {
        return;
    }

    AMDevice *device=[AMDevice deviceWithHandle:dev];

    if (AMDeviceGetInterfaceType(dev)!=AMDeviceInterfaceTypeUSB) {
        return;
    }

    int msg=info->msg;
    if (msg==ADNCI_MSG_CONNECTED) {
        [device WriteLine:@"Device Connected"];
        OnDeviceAttached(device);
    }
    if (msg==ADNCI_MSG_DISCONNECTED) {
        [device WriteLine:@"Device Disconnected"];
    }
}

void InitDeviceAttachListener(int sec){
    struct am_device_notification *notification = NULL;

    AMDeviceNotificationSubscribe(usbMuxMode, 0, 0, 0, &notification);
    if (sec==-1) {
        CFRunLoopRun();
    }else{
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, sec, NO);
    }
    AMDeviceNotificationUnsubscribe(notification);
}
