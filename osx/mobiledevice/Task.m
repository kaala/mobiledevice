//
//  Task.m
//  mobiledevice
//
//  Created by huangyi on 15/8/31.
//  Copyright (c) 2015年 wettags. All rights reserved.
//

#import "Task.h"

#import "CoreFoundation.h"
#import "MobileDevice.h"
#import "AMDevice.h"

@interface Task ()

@property(nonatomic,strong)AMDevice *device;

@end

@implementation Task

+(Task*)taskWithDevice:(AMDevice *)device{
    Task *task=[[Task alloc] init];
    task.device=device;
    return task;
}

-(void)InstallApp:(NSString*)appPath{
    if (!IsFileExists(appPath)) {
        [self.device WriteLine:@"InstallApp file"];
        return;
    }
    BOOL success=[self.device InstallApp:appPath];
    if (success) {
        [self.device WriteLine:@"InstallApp success"];
    }else{
        [self.device WriteLine:@"InstallApp fail"];
    }
}
-(void)UninstallApp:(NSString*)appId{
    NSDictionary *apps=[self.device LookupApps];
    if (!apps[appId]) {
        [self.device WriteLine:@"UninstallApp skip"];
        return;
    }
    BOOL success=[self.device UninstallApp:appId];
    if (success) {
        [self.device WriteLine:@"UninstallApp success"];
    }else{
        [self.device WriteLine:@"UninstallApp fail"];
    }
}

-(void)InstallProfile:(NSString*)profilePath{
    if (!IsFileExists(profilePath)) {
        [self.device WriteLine:@"InstallProfile file"];
        return;
    }
    BOOL success=[self.device InstallProfile:profilePath];
    if (success) {
        [self.device WriteLine:@"InstallProfile success"];
    }else{
        [self.device WriteLine:@"InstallProfile fail"];
    }
}
-(void)UninstallProfile:(NSString*)profileId{
    NSDictionary *profiles=[self.device LookupProfiles];
    if (!profiles[profileId]) {
        [self.device WriteLine:@"UninstallProfile skip"];
        return;
    }
    BOOL success=[self.device UninstallProfile:profileId];
    if (success) {
        [self.device WriteLine:@"UninstallProfile success"];
    }else{
        [self.device WriteLine:@"UninstallProfile fail"];
    }
}

-(void)ListApps{
    NSDictionary *apps=[self.device LookupApps];
    ShowApps(apps);
}
-(void)ListProfiles{
    NSDictionary *profiles=[self.device LookupProfiles];
    ShowProfiles(profiles);
}

-(void)Shutdown{
    BOOL success=[self.device Shutdown];
    if (success) {
        [self.device WriteLine:@"Shutdown success"];
    }else{
        [self.device WriteLine:@"Shutdown fail"];
    }
}
-(void)SyncTime{
    BOOL success=[self.device UpdateTime];
    if (success) {
        [self.device WriteLine:@"Sync success"];
    }else{
        [self.device WriteLine:@"Sync fail"];
    }
}

-(void)Execute:(NSDictionary *)args{
    NSString *cmd=args[@"command"];
    NSString *param=args[@"param"];

    if ([param hasSuffix:@".mobileconfig"]) {
        if ([cmd isEqual:@"install"]) {
            cmd=@"mcinstall";
        }
    }

    if ([cmd isEqual:@"install"]) {
        [self InstallApp:param];
        return;
    }
    if ([cmd isEqual:@"uninstall"]) {
        [self UninstallApp:param];
        return;
    }
    if ([cmd isEqual:@"mcinstall"]) {
        [self InstallProfile:param];
        return;
    }
    if ([cmd isEqual:@"mcuninstall"]) {
        [self UninstallProfile:param];
        return;
    }
    if ([cmd isEqual:@"device"]) {
        [self ListApps];
        [self ListProfiles];
        return;
    }
    if ([cmd isEqual:@"shutdown"]) {
        [self Shutdown];
        return;
    }
    if ([cmd isEqual:@"sleep"]) {
        int sec=param.intValue;
        sleep(sec);
        return;
    }
    if ([cmd isEqual:@"sync"]) {
        [self SyncTime];
        return;
    }
    if ([cmd isEqual:@"list"]) {
        if ([param isEqual:@"app"]) {
            [self ListApps];
        }
        if ([param isEqual:@"profile"]) {
            [self ListProfiles];
        }
        return;
    }
    if ([cmd isEqual:@"deploy"]) {
        if (!IsFileExists(param)) {
            [self.device WriteLine:@"BatchExecute file"];
            return;
        }
        NSStringEncoding enc=0;
        NSError *err=nil;
        NSString *contents=[NSString stringWithContentsOfFile:param usedEncoding:&enc error:&err];
        NSCharacterSet *nl=[NSCharacterSet newlineCharacterSet];
        NSArray *lines=[contents componentsSeparatedByCharactersInSet:nl];
        for (NSString *line in lines) {
            NSString *root=[[NSFileManager defaultManager] currentDirectoryPath];
            NSString *dir=[param stringByDeletingLastPathComponent];
            [[NSFileManager defaultManager] changeCurrentDirectoryPath:dir];
            NSCharacterSet *sp=[NSCharacterSet whitespaceCharacterSet];
            NSArray *rows=[line componentsSeparatedByCharactersInSet:sp];
            if (rows.count!=2) {
                continue;
            }
            NSString *arg1=rows[0];
            NSString *arg2=rows[1];
            NSDictionary *args=@{@"command":arg1.lowercaseString,@"param":arg2};
            Task *subtask=[Task taskWithDevice:self.device];
            [subtask Execute:args];
            [[NSFileManager defaultManager] changeCurrentDirectoryPath:root];
        }
        return;
    }

    NSString *msg=[NSString stringWithFormat:@"NoExecute %@",cmd];
    [self.device WriteLine:msg];
}

@end
