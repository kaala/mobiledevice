//
//  AMDevice.m
//  mobiledevice
//
//  Created by huangyi on 15/8/31.
//  Copyright (c) 2015年 wettags. All rights reserved.
//

#import "AMDevice.h"

#import "CoreFoundation.h"
#import "MobileDevice.h"



@interface AMDevice ()

@end

@implementation AMDevice

+(AMDevice *)deviceWithHandle:(struct am_device *)device{
    AMDevice *dev=[[AMDevice alloc] init];
    dev.device=device;
    return dev;
}

-(void)setDevice:(struct am_device *)device{
    _device=device;
    CFStringRef identifier=AMDeviceCopyDeviceIdentifier(device);
    NSString *deviceId=[NSString stringWithString:(__bridge NSString *)(identifier)];
    _device_id=deviceId;
}


-(NSString*)deviceId{
    return self.device_id;
}

-(void)WriteLine:(NSString *)message{
    NSString *msg=[NSString stringWithFormat:@"%@ %@",self.device_id,message];
    WriteLine(msg);
}


-(BOOL)Connect{
    return Connect(self);
}
-(BOOL)Disconnect{
    return Disconnect(self);
}
-(BOOL)ValidatePairing{
    return ValidatePairing(self);
}
-(BOOL)StartSession{
    return StartSession(self);
}
-(BOOL)StopSession{
    return StopSession(self);
}

-(BOOL)StartService:(const NSString *)serviceName{
    return StartService(self, serviceName);
}
-(NSDictionary*)TransferPlist:(NSDictionary*)dict{
    if (!dict) {
        return nil;
    }
    NSError *error = nil;
    NSPropertyListFormat format = NSPropertyListXMLFormat_v1_0;
    NSData *source = [NSPropertyListSerialization dataWithPropertyList:dict format:format options:NSPropertyListWriteStreamError error:&error];
    NSData *dest=SocketIO(self, source);
    NSDictionary *output = [NSPropertyListSerialization propertyListWithData:dest options:NSPropertyListReadStreamError format:&format error:&error];
    return output;
}
-(BOOL)Flush{
    NSDictionary *dict=@{ @"RequestType":@"Flush" };
    NSDictionary *received=[self TransferPlist:dict];
    if (!received) {
        return false;
    }
    return true;
}


-(NSDictionary *)LookupApps{
    return LookupApps(self);
}

-(BOOL)InstallApp:(NSString *)appPath{
    if (!IsFileExists(appPath)) {
        return false;
    }
    return InstallApp(self, appPath);
}
-(BOOL)UninstallApp:(NSString *)appId{
    return UninstallApp(self, appId);
}


-(NSDictionary *)LookupProfiles{
    if (![self StartService:SVC_MCINSTALL]) {
        return nil;
    }
    NSDictionary *dict=@{ @"RequestType":@"GetProfileList" };
    NSDictionary *profiles=[self TransferPlist:dict];
    NSDictionary *metas=profiles[ProfileMetadata];
    return metas;
}

-(BOOL)InstallProfile:(NSString *)profilePath{
    if (!IsFileExists(profilePath)) {
        return false;
    }
    if (![self StartService:SVC_MCINSTALL]) {
        return false;
    }
    NSData *data=[NSData dataWithContentsOfFile:profilePath];
    NSDictionary *dict=@{ @"RequestType":@"InstallProfile",@"Payload":data };
    NSDictionary *received=[self TransferPlist:dict];
    NSString *status=received[@"Status"];
    [self Flush];
    return [status isEqual:@"Acknowledged"];
}
-(BOOL)UninstallProfile:(NSString *)profileId{
    if (![self StartService:SVC_MCINSTALL]) {
        return false;
    }
    NSDictionary *dict=@{ @"RequestType":@"RemoveProfile",@"ProfileIdentifier":profileId };
    NSDictionary *received=[self TransferPlist:dict];
    NSString *status=received[@"Status"];
    [self Flush];
    return [status isEqual:@"Acknowledged"];
}


-(BOOL)Shutdown{
    if (![self StartService:SVC_DIAGNOSTICS_RELAY]) {
        return false;
    }
    NSDictionary *dict=@{ @"Request":@"Shutdown" };
    NSDictionary *received=[self TransferPlist:dict];
    NSString *status=received[@"Status"];
    [self Flush];
    return [status isEqual:@"Acknowledged"];
}
-(BOOL)UpdateTime{
    if (![self StartService:SVC_MISAGENT]) {
        return false;
    }
    NSTimeInterval tk=[[NSDate date] timeIntervalSince1970];
    NSDictionary *dict=@{ @"Request":@"SetValue", @"Domain":@(0), @"Key":@"TimeIntervalSince1970", @"Value":@(tk) };
    NSDictionary *received=[self TransferPlist:dict];
    NSString *status=[NSString stringWithFormat:@"%@",received[@"Status"]];
    [self Flush];
    return [status isEqual:@"0"];
}

@end
