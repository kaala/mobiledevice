//
//  CoreFoundation.h
//  mobiledevice
//
//  Created by huangyi on 15/8/31.
//  Copyright (c) 2015年 wettags. All rights reserved.
//

#import <Foundation/Foundation.h>


BOOL IsFileExists(NSString *fp);
NSArray *ParseArgs(int argc,const char * argv[]);

void WriteLine(NSString *message);
void WriteError(NSString *message);
