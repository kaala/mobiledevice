//
//  Task.m
//  mobiledevice
//
//  Created by huangyi on 15/8/31.
//  Copyright (c) 2015年 wettags. All rights reserved.
//

#import "Task.h"

#import "AMDevice.h"
#import "CoreFoundation.h"
#import "MobileDevice.h"

@interface Task ()

@property(nonatomic, strong) AMDevice *device;

@end

@implementation Task

+ (Task *)taskWithDevice:(AMDevice *)device {
    Task *task = [[Task alloc] init];
    task.device = device;
    return task;
}

- (void)InstallApp:(NSString *)appPath {
    if (!IsFileExists(appPath)) {
        [self.device WriteLine:@"InstallApp NoFile"];
        return;
    }
    BOOL success = [self.device InstallApp:appPath];
    if (success) {
        [self.device WriteLine:@"InstallApp Ok"];
    } else {
        [self.device WriteLine:@"InstallApp Error"];
    }
}
- (void)UninstallApp:(NSString *)appId {
    NSDictionary *apps = [self.device LookupApps];
    if (!apps[appId]) {
        [self.device WriteLine:@"UninstallApp Skip"];
        return;
    }
    BOOL success = [self.device UninstallApp:appId];
    if (success) {
        [self.device WriteLine:@"UninstallApp Ok"];
    } else {
        [self.device WriteLine:@"UninstallApp Error"];
    }
}

- (void)InstallProfile:(NSString *)profilePath {
    if (!IsFileExists(profilePath)) {
        [self.device WriteLine:@"InstallProfile NoFile"];
        return;
    }
    BOOL success = [self.device InstallProfile:profilePath];
    if (success) {
        [self.device WriteLine:@"InstallProfile Ok"];
    } else {
        [self.device WriteLine:@"InstallProfile Error"];
    }
}
- (void)UninstallProfile:(NSString *)profileId {
    NSDictionary *profiles = [self.device LookupProfiles];
    if (!profiles[profileId]) {
        [self.device WriteLine:@"UninstallProfile Skip"];
        return;
    }
    BOOL success = [self.device UninstallProfile:profileId];
    if (success) {
        [self.device WriteLine:@"UninstallProfile Ok"];
    } else {
        [self.device WriteLine:@"UninstallProfile Error"];
    }
}

- (void)ListApps {
    NSDictionary *apps = [self.device LookupApps];
    ShowApps(apps);
}
- (void)ListProfiles {
    NSDictionary *profiles = [self.device LookupProfiles];
    ShowProfiles(profiles);
}

- (void)Shutdown {
    BOOL success = [self.device Shutdown];
    if (success) {
        [self.device WriteLine:@"Shutdown Ok"];
    } else {
        [self.device WriteLine:@"Shutdown Error"];
    }
}
- (void)CopyFile:(NSString *)copy {
    BOOL success = [self.device CopyFile:copy];
    if (success) {
        [self.device WriteLine:@"CopyFile Ok"];
    } else {
        [self.device WriteLine:@"CopyFile Error"];
    }
}
- (void)SyncTime {
    BOOL success = [self.device SyncTime];
    if (success) {
        [self.device WriteLine:@"Sync Ok"];
    } else {
        [self.device WriteLine:@"Sync Error"];
    }
}

- (void)Run:(NSDictionary *)args {
    NSString *cmd = args[@"command"];
    NSString *param = args[@"param"];

    if ([param hasSuffix:@".mobileconfig"]) {
        if ([cmd isEqual:@"install"]) {
            cmd = @"mcinstall";
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
        int sec = param.intValue;
        sleep(sec);
        return;
    }
    if ([cmd isEqual:@"copy"]) {
        [self CopyFile:param];
        return;
    }
    if ([cmd isEqual:@"sync"]) {
        if ([param isEqual:@"time"]) {
            [self SyncTime];
        }
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
            [self.device WriteLine:@"BatchExec NoFile"];
            return;
        }
        NSStringEncoding enc = 0;
        NSError *err = nil;
        NSString *contents = [NSString stringWithContentsOfFile:param usedEncoding:&enc error:&err];
        NSCharacterSet *nl = [NSCharacterSet newlineCharacterSet];
        NSArray *lines = [contents componentsSeparatedByCharactersInSet:nl];
        for (NSString *line in lines) {
            NSString *root = [[NSFileManager defaultManager] currentDirectoryPath];
            NSString *dir = [param stringByDeletingLastPathComponent];
            [[NSFileManager defaultManager] changeCurrentDirectoryPath:dir];
            NSCharacterSet *sp = [NSCharacterSet whitespaceCharacterSet];
            NSArray *rows = [line componentsSeparatedByCharactersInSet:sp];
            if (rows.count != 2) {
                continue;
            }
            NSString *arg1 = rows[0];
            NSString *arg2 = rows[1];
            NSDictionary *args = @{ @"command" : arg1.lowercaseString, @"param" : arg2 };
            Task *subtask = [Task taskWithDevice:self.device];
            [subtask Run:args];
            [[NSFileManager defaultManager] changeCurrentDirectoryPath:root];
        }
        return;
    }

    NSString *msg = [NSString stringWithFormat:@"NotAvailable %@", cmd];
    [self.device WriteLine:msg];
}

@end
