//
//  main.m
//  mobiledevice
//
//  Created by huangyi on 15/8/31.
//  Copyright (c) 2015年 wettags. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CoreFoundation.h"
#import "MobileDevice.h"
#import "AMDevice.h"
#import "Task.h"

static NSDictionary *inArgs=nil;

int main(int argc, const char * argv[]) {

    NSArray *args=ParseArgs(argc,argv);

    if (args.count==1) {
        NSString *fp=args[0];
        if (IsFileExists(fp)) {
            args=@[@"deploy",fp];
        }
    }

    if (args.count!=2) {
        WriteError(@"available commands: list | deploy | install | uninstall | mcinstall | mcuninstall");
        WriteError([args componentsJoinedByString:@" "]);
        ThreadSleep(3);
        return EXIT_FAILURE;
    }

    NSString *cmd=args[0];
    NSString *param=args[1];
    NSDictionary *dict=@{@"command":cmd.lowercaseString,@"param":param};
    inArgs=dict;

    int timeout=5;
    if ([cmd isEqual:@"deploy"]) {
        timeout=-1;
    }

    InitDeviceAttachListener(timeout);

    return EXIT_SUCCESS;
}

BOOL Run(AMDevice *device){
    if (![device Connect]) {
        [device WriteLine:@"Connect error"];
        return false;
    }
    if (![device ValidatePairing]) {
        [device WriteLine:@"Pairing error"];
        return false;
    }
    if (![device StartSession]) {
        [device WriteLine:@"Session error"];
        [device Disconnect];
        return false;
    }

    NSDictionary *args=inArgs;
    Task *task=[Task taskWithDevice:device];
    [task Execute:args];

    [device StopSession];
    [device Disconnect];

    [device WriteLine:@"Execute success"];
    return true;
}

BOOL OnDeviceAttached(AMDevice *device){
    @try {
        return Run(device);
    }
    @catch (NSException *exception) {
        [device WriteLine:exception.reason];
        return false;
    }
}
