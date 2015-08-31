//
//  MobileDevice.h
//  mobiledevice
//
//  Created by huangyi on 15/8/31.
//  Copyright (c) 2015年 wettags. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "itunes.h"


extern const NSString *SVC_INSTALLATION_PROXY;
extern const NSString *SVC_MCINSTALL;
extern const NSString *SVC_DIAGNOSTICS_RELAY;
extern const NSString *SVC_MISAGENT;

extern const NSString *ProfileMetadata;
extern const NSString *OrderedIdentifiers;
extern const NSString *PayloadDisplayName;
extern const NSString *PayloadOrganization;
extern const NSString *PayloadIdentifier;

extern const NSString *CFBundleIdentifier;
extern const NSString *ApplicationType;
extern const NSString *CFBundleName;
extern const NSString *CFBundleDisplayName;
extern const NSString *CFBundleShortVersionString;
extern const NSString *CFBundleVersion;


@class AMDevice;


BOOL Connect(AMDevice *device);
BOOL Disconnect(AMDevice *device);
BOOL ValidatePairing(AMDevice *device);
BOOL StartSession(AMDevice *device);
BOOL StopSession(AMDevice *device);

BOOL StartService(AMDevice *device,const NSString *service);
NSData *SocketIO(AMDevice *device,NSData *source);

NSDictionary* LookupApps(AMDevice *device);
BOOL InstallApp(AMDevice *device,NSString *appPath);
BOOL UninstallApp(AMDevice *device,NSString *appId);

void ShowApps(NSDictionary *apps);
void ShowProfiles(NSDictionary *profiles);

void InitDeviceAttachListener(int sec);