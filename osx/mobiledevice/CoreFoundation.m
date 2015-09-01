//
//  CoreFoundation.m
//  mobiledevice
//
//  Created by huangyi on 15/8/31.
//  Copyright (c) 2015年 wettags. All rights reserved.
//

#import "CoreFoundation.h"


BOOL IsFileExists(NSString *fp){
    return [[NSFileManager defaultManager] fileExistsAtPath:fp];
}

NSArray *ParseArgs(int argc,const char * argv[]){
    NSMutableArray *args=[NSMutableArray arrayWithCapacity:argc];
    for (int i=1; i<argc; i++) {
        NSString *arg=[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding];
        [args addObject:arg];
    }
    return args;
};

void WriteLine(NSString *message){
    fprintf(stdout, "%s\n",message.UTF8String);
}
void WriteError(NSString *message){
    fprintf(stderr, "%s\n",message.UTF8String);
}

void ThreadSleep(int sec){
    if (sec==-1) {
        CFRunLoopRun();
    }else{
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, sec, NO);
    }
}

