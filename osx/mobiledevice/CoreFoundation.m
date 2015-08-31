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
    NSFileHandle *fh=[NSFileHandle fileHandleWithStandardOutput];
    message=[message stringByAppendingString:@"\n"];
    NSData *data=[message dataUsingEncoding:NSUTF8StringEncoding];
    [fh writeData:data];
    [fh synchronizeFile];
}
void WriteError(NSString *message){
    NSFileHandle *fh=[NSFileHandle fileHandleWithStandardError];
    message=[message stringByAppendingString:@"\n"];
    NSData *data=[message dataUsingEncoding:NSUTF8StringEncoding];
    [fh writeData:data];
    [fh synchronizeFile];
}

void ThreadSleep(int sec){
    if (sec==-1) {
        CFRunLoopRun();
    }else{
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, sec, NO);
    }
}

