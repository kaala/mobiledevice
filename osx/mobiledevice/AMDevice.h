//
//  AMDevice.h
//  mobiledevice
//
//  Created by huangyi on 15/8/31.
//  Copyright (c) 2015年 wettags. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "itunes.h"

@interface AMDevice : NSObject

@property (nonatomic)  struct am_device *device;
@property (nonatomic) int socket_fd;
@property (nonatomic) NSString *device_id;

+(AMDevice *)deviceWithHandle:(struct am_device *)device;
-(void)WriteLine:(NSString *)message;

-(NSString*)deviceId;

-(BOOL)Connect;
-(BOOL)Disconnect;
-(BOOL)ValidatePairing;
-(BOOL)StartSession;
-(BOOL)StopSession;

-(BOOL)StartService:(const NSString *)serviceName;
-(NSDictionary *)TransferPlist:(NSDictionary *)dict;
-(BOOL)Flush;

-(NSDictionary *)LookupApps;
-(BOOL)InstallApp:(NSString *)appPath;
-(BOOL)UninstallApp:(NSString *)appId;

-(NSDictionary *)LookupProfiles;
-(BOOL)InstallProfile:(NSString *)profilePath;
-(BOOL)UninstallProfile:(NSString *)profileId;

-(BOOL)Shutdown;
-(BOOL)UpdateTime;

@end
