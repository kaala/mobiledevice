//
//  main.c
//  mob
//
//  Created by huangyi on 14/11/19.
//  Copyright (c) 2014年 huangyi. All rights reserved.
//

#include <stdio.h>
#include <sys/socket.h>
#import <Foundation/Foundation.h>

#import "mobiledevice.h"

__DLLIMPORT uint32_t AMDeviceGetInterfaceType(struct am_device *device);

enum {
    AMDeviceInterfaceTypeUSB = 1,
    AMDeviceInterfaceTypeWifi = 2
};

extern void execute_on_device(struct am_device *device,NSString *cmd,NSString *param);

NSOperationQueue *deploy;
NSMutableSet *devices=nil;
NSDictionary *arguments=nil;
struct am_device_notification *notification=NULL;

enum {
    DEVICE_DETECT_MODE,
    SINGLE_DEVICE_MODE,
    MASS_DEPLOY_MODE
};

void output(const char* s)
{
    if (s)
    {
        printf("%s\n",s);
    }
}

void die(int c,const char* s)
{
    if (!c)
    {
        NSString *str=[NSString stringWithUTF8String:s];
        NSException *e=[NSException exceptionWithName:NSGenericException reason:str userInfo:nil];
        @throw e;
    }
}

int start_service(struct am_device *device,NSString *service)
{
    int sock=0;
    CFStringRef name=CFBridgingRetain(service);
    die(!AMDeviceStartService(device,name, &sock), "!AMDeviceStartService");
    CFBridgingRelease(name);
    return sock;
}

BOOL socket_send_request(int service,NSData *message)
{
    bool result = NO;
    CFDataRef messageAsXML = CFBridgingRetain(message);
    if (messageAsXML) {
        CFIndex xmlLength = CFDataGetLength(messageAsXML);
        int sock = service;
        uint32_t sz;
        sz = htonl(xmlLength);
        if (send(sock, &sz, sizeof(sz), 0) != sizeof(sz)) {
            output("!SOCKET_SEND_SIZE");//Can't send message size
        } else {
            if (send(sock, CFDataGetBytePtr(messageAsXML), xmlLength,0) != xmlLength) {
                output("!SOCKET_SEND_TEXT");//Can't send message text
            } else {
                result = YES;
            }
        }
        CFBridgingRelease(messageAsXML);
    } else {
        output("!SOCKET_SEND_CONVERTXML");//Can't convert request to XML
    }
    return result;
}
NSData *socket_receive_response(int service)
{
    NSData *result = nil;
    int sock = service;
    uint32_t sz;
    if (sizeof(uint32_t) != recv(sock, &sz, sizeof(sz), 0)) {
        output("!SOCKET_RECV_SIZE");//Can't receive reply size
    } else {
        sz = ntohl(sz);
        if (sz) {
            unsigned char *buff = malloc(sz);
            unsigned char *p = buff;
            uint32_t left = sz;
            while (left) {
                long rc =recv(sock, p, left,0);
                if (rc==0) {
                    output("!SOCKET_RECV_TRUNCATED");//Reply was truncated, expected %d more bytes
                    free(buff);
                    return(nil);
                }
                left -= rc;
                p += rc;
            }
            CFDataRef r = CFDataCreateWithBytesNoCopy(0,buff,sz,kCFAllocatorNull);
            result=CFBridgingRelease(r);
            free(buff);
        }
    }
    return result;
}
NSDictionary *socket_send_xml(int sock,NSDictionary *message)
{
    NSDictionary *dict=nil;
    if (message) {
        NSError *error=nil;
        NSPropertyListFormat format=NSPropertyListXMLFormat_v1_0;
        NSData *send=[NSPropertyListSerialization dataWithPropertyList:message format:format options:NSPropertyListWriteStreamError error:&error];
        socket_send_request(sock, send);
        NSData *recv=socket_receive_response(sock);
        if (recv) {
            dict=[NSPropertyListSerialization propertyListWithData:recv options:NSPropertyListReadStreamError format:&format error:&error];
        }
    }
    return dict;
}

BOOL is_file_exist(NSString *path)
{
    BOOL dir=NO;
    NSFileManager *fm=[NSFileManager defaultManager];
    BOOL exist=[fm fileExistsAtPath:path isDirectory:&dir];
    return exist;
}

NSString *read_file(NSString *path)
{
    NSStringEncoding encoding=0;
    NSError *error=nil;
    NSString *text=[NSString stringWithContentsOfFile:path usedEncoding:&encoding error:&error];
    return text;
}

NSString *get_udid(struct am_device *device)
{
    CFStringRef identifier=AMDeviceCopyDeviceIdentifier(device);
    NSString *udid=CFBridgingRelease(identifier);
    return udid;
}

static void install_app(struct am_device *device,NSString* app_path)
{
    @try {
        die(is_file_exist(app_path), "!FILE_NOT_EXIST");
        NSURL *file_url=[NSURL fileURLWithPath:app_path];
        NSDictionary *dict=@{ @"PackageType" : @"Developer" };
        CFURLRef local_app_url=CFBridgingRetain(file_url);
        CFDictionaryRef options = CFBridgingRetain(dict);
        die(!AMDeviceSecureTransferPath(0, device, local_app_url, options, NULL, 0), "!AMDeviceSecureTransferPath");
        die(!AMDeviceSecureInstallApplication(0, device, local_app_url, options, NULL, 0), "!AMDeviceSecureInstallApplication");
        CFBridgingRelease(options);
        CFBridgingRelease(local_app_url);
    }
    @catch (NSException *exception) {
        @throw exception;
    }
}
static void uninstall_app(struct am_device *device,NSString *app_id)
{
    @try {
        CFStringRef bundle_id=CFBridgingRetain(app_id);
        die(!AMDeviceSecureUninstallApplication(0, device, bundle_id, 0, NULL, 0), "!AMDeviceSecureUninstallApplication");
        CFBridgingRelease(bundle_id);
    }
    @catch (NSException *exception) {
        @throw exception;
    }
}
static void list_app(struct am_device *device)
{
    @try {
        CFDictionaryRef apps;
        die(!AMDeviceLookupApplications(device, 0, &apps), "!AMDeviceLookupApplications\n");
        NSDictionary *dict=CFBridgingRelease(apps);
        NSMutableArray *row=[NSMutableArray array];
        if ([arguments[@"verbose"] boolValue]) {
            NSString *line=[dict description];
            [row addObject:line];
        }else{
            NSArray *arr=[dict allKeys];
            NSUInteger len=0;
            for (NSString *k in arr) {
                len=MAX(len, k.length);
            }
            for (NSString *k in arr) {
                NSDictionary *info=dict[k];
                NSString *bundle=info[@"CFBundleIdentifier"];
                bundle=[bundle stringByPaddingToLength:len+4 withString:@" " startingAtIndex:0];
                NSString *type=info[@"ApplicationType"];
                type=[type stringByPaddingToLength:12 withString:@" " startingAtIndex:0];
                NSString *name=info[@"CFBundleDisplayName"];
                NSString *version=info[@"CFBundleShortVersionString"];
                NSString *build=info[@"CFBundleVersion"];
                NSString *line=[NSString stringWithFormat:@"%@%@%@:%@(%@)",bundle,type,name,version,build];
                [row addObject:line];
            }
        }
        if (row.count) {
            NSString *o=[row componentsJoinedByString:@"\n"];
            output(o.UTF8String);
        }
    }
    @catch (NSException *exception) {
        @throw exception;
    }
}

static void install_mc(struct am_device *device,NSString *mc_path)
{
    @try {
        die(is_file_exist(mc_path), "!FILE_NOT_EXIST");
        int sock=start_service(device,@"com.apple.mobile.MCInstall");
        socket_send_xml(sock, @{ @"RequestType":@"Flush" });
        NSData *payload=[NSData dataWithContentsOfFile:mc_path];
        NSDictionary *dict=socket_send_xml(sock, @{ @"RequestType":@"InstallProfile", @"Payload":payload });
        if ([arguments[@"verbose"] boolValue]) {
            NSString *o=[dict description];
            output(o.UTF8String);
        }
    }
    @catch (NSException *exception) {
        @throw exception;
    }
}
static void uninstall_mc(struct am_device *device, NSString *mc_id)
{
    @try {
        int sock=start_service(device,@"com.apple.mobile.MCInstall");
        socket_send_xml(sock, @{ @"RequestType":@"Flush" });
        NSDictionary *dict=socket_send_xml(sock, @{ @"RequestType":@"RemoveProfile", @"ProfileIdentifier":mc_id });
        if ([arguments[@"verbose"] boolValue]) {
            NSString *o=[dict description];
            output(o.UTF8String);
        }
    }
    @catch (NSException *exception) {
        @throw exception;
    }
}
static void list_mc(struct am_device *device)
{
    @try {
        int sock=start_service(device,@"com.apple.mobile.MCInstall");
        socket_send_xml(sock, @{ @"RequestType":@"Flush" });
        NSDictionary *dict=socket_send_xml(sock, @{ @"RequestType":@"GetProfileList" });
        NSMutableArray *row=[NSMutableArray array];
        if ([arguments[@"verbose"] boolValue]) {
            NSString *line=[dict description];
            [row addObject:line];
        }else{
            NSArray *arr=dict[@"OrderedIdentifiers"];
            NSDictionary *meta=dict[@"ProfileMetadata"];
            NSUInteger len=0;
            for (NSString *k in arr) {
                len=MAX(len, k.length);
            }
            for (NSString *k in arr) {
                NSDictionary *info=meta[k];
                NSString *bundle=k;
                bundle=[bundle stringByPaddingToLength:len+4 withString:@" " startingAtIndex:0];
                NSString *org=info[@"PayloadOrganization"];
                NSString *name=info[@"PayloadDisplayName"];
                NSString *line=[NSString stringWithFormat:@"%@%@(%@)",bundle,name,org];
                [row addObject:line];
            }
        }
        if (row.count) {
            NSString *o=[row componentsJoinedByString:@"\n"];
            output(o.UTF8String);
        }
    }
    @catch (NSException *exception) {
        @throw exception;
    }
}

void add_device_to_queue(struct am_device *device)
{
    NSOperation *operate=[NSBlockOperation blockOperationWithBlock:^{
        @try {
            NSString *param=arguments[@"param"];
            die(!!param,"!PARAM");
            NSString *config=read_file(param);
            NSCharacterSet *nl=[NSCharacterSet newlineCharacterSet];
            NSCharacterSet *sp=[NSCharacterSet whitespaceCharacterSet];
            NSArray *sequence=[config componentsSeparatedByCharactersInSet:nl];
            for (NSString *row in sequence) {
                NSArray *arg=[row componentsSeparatedByCharactersInSet:sp];
                if (arg.count==2) {
                    @try {
                        NSString *cmd=arg[0];
                        NSString *param=arg[1];
                        execute_on_device(device, cmd, param);
                    }
                    @catch (NSException *exception) {
                        NSString *o=[exception description];
                        output(o.UTF8String);
                    }
                }
            }
            NSString *udid=get_udid(device);
            NSString *o=[NSString stringWithFormat:@"COMPLETE %@",udid];
            output(o.UTF8String);
        }
        @catch (NSException *exception) {
            NSString *o=[exception description];
            output(o.UTF8String);
        }
    }];
    [deploy addOperation:operate];
}

void on_device_connect(struct am_device *device,int cookie)
{
    if (cookie==MASS_DEPLOY_MODE) {
        NSString *s=get_udid(device);
        NSString *o=[NSString stringWithFormat:@"CONNECT %@",s];
        output(o.UTF8String);
        add_device_to_queue(device);
    }

    if (cookie==SINGLE_DEVICE_MODE) {
        NSString *udid=get_udid(device);
        NSString *device_udid=arguments[@"udid"];
        if (!device_udid) {
            device_udid=udid;
        }
        if ([device_udid isEqualToString:udid]) {
            @try {
                NSString *cmd=arguments[@"command"];
                NSString *param=arguments[@"param"];
                execute_on_device(device,cmd,param);
            }
            @catch (NSException *exception) {
                NSString *o=[exception description];
                output(o.UTF8String);
                exit(EXIT_FAILURE);
            }
            exit(EXIT_SUCCESS);
        }
    }
}
void on_device_disconnect(struct am_device *device,int cookie)
{
    if (cookie==MASS_DEPLOY_MODE) {
        NSString *s=get_udid(device);
        NSString *o=[NSString stringWithFormat:@"DISCONNECT %@",s];
        output(o.UTF8String);
    }
}

void on_device_notification(struct am_device_notification_callback_info *info, int cookie)
{
    struct am_device *device=info->dev;
    if (AMDeviceGetInterfaceType(device) != AMDeviceInterfaceTypeUSB)
    {
        return;
    }
    if (info->msg == ADNCI_MSG_CONNECTED)
    {
        NSString *s=get_udid(device);
        [devices addObject:s];
        on_device_connect(device,cookie);
    }
    if (info->msg == ADNCI_MSG_DISCONNECTED)
    {
        NSString *s=get_udid(device);
        [devices removeObject:s];
        on_device_disconnect(device,cookie);
    }
}

void register_device_notification(int cookie)
{
    AMDeviceNotificationSubscribe(&on_device_notification, 0, 0, cookie, &notification);
}
void unregister_device_notification()
{
    AMDeviceNotificationUnsubscribe(notification);
}

void parse_args(NSDictionary *args)
{
    arguments=args;
    devices=[NSMutableSet set];

    if ([arguments[@"verbose"] boolValue]) {
        NSString *o=[args description];
        output(o.UTF8String);
    }

    if ([arguments[@"preview"] boolValue]) {
        exit(EXIT_SUCCESS);
    }

    if (!arguments[@"command"]) {
        output("COMMANDS: [devices|deploy|install|uninstall|list|mc_install|mc_uninstall|mc_list]");
        output("Detail: https://github.com/kaala/mobiledevice");
        output("");
        exit(EXIT_FAILURE);
    }

    NSString *cmd=arguments[@"command"];

    if ([cmd isEqualToString:@"devices"]) {
        register_device_notification(DEVICE_DETECT_MODE);
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, NO);
        unregister_device_notification();

        NSArray *udids=[devices allObjects];
        NSString *o=[udids componentsJoinedByString:@"\n"];
        output(o.UTF8String);

        exit(EXIT_SUCCESS);
    }

    if ([cmd isEqualToString:@"deploy"]){
        @try {
            NSString *param=arguments[@"param"];
            die(!!param,"!PARAM");
        }
        @catch (NSException *exception) {
            NSString *o=[exception description];
            output(o.UTF8String);
            exit(EXIT_FAILURE);
        }

        deploy=[[NSOperationQueue alloc] init];
        deploy.maxConcurrentOperationCount=5;

        register_device_notification(MASS_DEPLOY_MODE);
        CFRunLoopRun();
        unregister_device_notification();

        exit(EXIT_SUCCESS);
    }

    if (cmd){
        register_device_notification(SINGLE_DEVICE_MODE);
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 20, NO);
        unregister_device_notification();

        output("!DEVICE_NOT_FOUND");
        exit(EXIT_FAILURE);
    }
}

int main(int argc, const char * argv[]) {
    NSMutableDictionary *parse=[NSMutableDictionary dictionary];
    NSString *key=@"command";
    for (int i=1; i<argc; i++) {
        NSString *obj=[NSString stringWithUTF8String:argv[i]];
        if ([obj hasPrefix:@"-"]) {
            if ([obj isEqualToString:@"-v"] || [obj isEqualToString:@"-verbose"]) {
                parse[@"verbose"]=@(YES);
            }else if ([obj isEqualToString:@"-p"] || [obj isEqualToString:@"-preview"]){
                parse[@"verbose"]=@(YES);
                parse[@"preview"]=@(YES);
            }else{
                key=[obj substringFromIndex:1];
            }
        }else{
            if (key) {
                parse[key]=obj;
                key=nil;
            }else{
                parse[@"param"]=obj;
            }
        }
    }
    parse_args(parse);
    return EXIT_SUCCESS;
}

void execute_on_device(struct am_device *device,NSString *cmd,NSString *param)
{
    if ([cmd isEqualToString:@"sleep"]) {
        int seconds=[param intValue];
        sleep(seconds);
        return;
    }

    die(!AMDeviceConnect(device),"!AMDeviceConnect");
    die(AMDeviceIsPaired(device),"!AMDeviceIsPaired");
    die(!AMDeviceValidatePairing(device),"!AMDeviceValidatePairing");
    die(!AMDeviceStartSession(device),"!AMDeviceStartSession");

    NSException *exc=nil;
    @try {
        if ([cmd isEqualToString:@"install"]) {
            die(!!param,"!PARAM");
            install_app(device, param);
        }
        if ([cmd isEqualToString:@"uninstall"]) {
            die(!!param,"!PARAM");
            uninstall_app(device, param);
        }
        if ([cmd isEqualToString:@"list"]) {
            list_app(device);
        }
        if ([cmd isEqualToString:@"mc_install"]) {
            die(!!param,"!PARAM");
            install_mc(device, param);
        }
        if ([cmd isEqualToString:@"mc_uninstall"]) {
            die(!!param,"!PARAM");
            uninstall_mc(device, param);
        }
        if ([cmd isEqualToString:@"mc_list"]) {
            list_mc(device);
        }
    }
    @catch (NSException *exception) {
        exc=exception;
    }

    die(!AMDeviceStopSession(device),"!AMDeviceStopSession");
    die(!AMDeviceDisconnect(device),"!AMDeviceDisconnect");

    if (exc) {
        NSString *o=[exc description];
        die(0, o.UTF8String);
    }else{
        NSString *o=[NSString stringWithFormat:@"!OK %@",cmd.uppercaseString];
        output(o.UTF8String);
    }
}
