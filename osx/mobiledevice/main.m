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
static NSOperationQueue *taskQueue=nil;

int main(int argc, const char * argv[]) {
    setvbuf(stdout, NULL, _IOLBF, _IONBF);

    WriteError(@"Running on mac");
    system("killall iTunesHelper 2>/dev/null");

    NSArray *args=ParseArgs(argc,argv);

    if (args.count==1) {
        NSString *fp=args[0];
        args=@[@"deploy",fp];
    }

    if (args.count!=2) {
        WriteError(@"available commands: list | deploy | install | uninstall | mcinstall | mcuninstall");
        WriteError([args componentsJoinedByString:@" "]);
        sleep(3);
        return EXIT_FAILURE;
    }

    NSString *cmd=args[0];
    NSString *param=args[1];
    NSDictionary *dict=@{@"command":cmd.lowercaseString,@"param":param};
    inArgs=dict;

    if ([cmd isEqual:@"deploy"]) {
        if (!IsFileExists(param)) {
            WriteError(@"BatchExecute file");
            sleep(3);
            return EXIT_FAILURE;
        }
    }

    int timeout=5;
    if ([cmd isEqual:@"deploy"]) {
        timeout=-1;
    }

    NSOperationQueue *queue=[[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:5];
    taskQueue=queue;

    InitDeviceAttachListener(timeout);

    [queue waitUntilAllOperationsAreFinished];

    return EXIT_SUCCESS;
}

BOOL Run(AMDevice *device){
    @try {
        if (![device Connect]) {
            [device WriteLine:@"Connect error"];
            return false;
        }
        if (![device ValidatePairing]) {
            sleep(15);
        }
        if (![device ValidatePairing]) {
            sleep(15);
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
    @catch (NSException *exception) {
        [device WriteLine:exception.reason];
        return false;
    }
}

BOOL OnDeviceAttached(AMDevice *device){
    NSOperation *operation=[NSBlockOperation blockOperationWithBlock:^{
        Run(device);
    }];
    [taskQueue addOperation:operation];
    return true;
}
