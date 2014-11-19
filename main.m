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

enum {
    AMDeviceInterfaceTypeUSB = 1,
    AMDeviceInterfaceTypeWifi = 2
};
__DLLIMPORT uint32_t AMDeviceGetInterfaceType(struct am_device *device);

extern void register_device_notification(int cookie);
extern void unregister_device_notification();

extern void on_device_notification(struct am_device_notification_callback_info *info, int cookie);
extern void on_device_connected(struct am_device *device);
extern void on_device_disconnected(struct am_device *device);

extern void execute_on_device(struct am_device *device);

struct am_device_notification *notification=NULL;
NSMutableSet *devices=nil;
NSArray *args=nil;

static void success(const char* s)
{
    if (s)
    {
        printf("%s\n",s);
    }
    unregister_device_notification();
    exit(EXIT_SUCCESS);
}
static void output(const char* s)
{
    if (s)
    {
        printf("%s\n",s);
    }
}
static void die(int c,const char* s)
{
    if (!c)
    {
        if (s)
        {
            printf("%s\n",s);
        }
        unregister_device_notification();
        exit(EXIT_FAILURE);
    }
}

static void connect_to_device(struct am_device *device)
{
    AMDeviceConnect(device);
    die(AMDeviceIsPaired(device), "!AMDeviceIsPaired");
    die(!AMDeviceValidatePairing(device), "!AMDeviceValidatePairing");
    die(!AMDeviceStartSession(device), "!AMDeviceStartSession");
}
static void disconnect_from_device(struct am_device *device)
{
    AMDeviceStopSession(device);
    AMDeviceDisconnect(device);
}

static int start_service(struct am_device *device,NSString *service)
{
    int sock=0;
    CFStringRef name=CFBridgingRetain(service);
    die(!AMDeviceStartService(device,name, &sock), "!AMDeviceStartService");
    CFBridgingRelease(name);
    return sock;
}

static BOOL socket_send_request(int service,NSData *message)
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
static NSData *socket_receive_response(int service)
{
    NSData *result = nil;
    int sock = service;
    uint32_t sz;
    if (sizeof(uint32_t) != recv(sock, &sz, sizeof(sz), 0)) {
        output("!SOCKET_RECV_NOREPLY");//Can't receive reply size
    } else {
        sz = ntohl(sz);
        if (sz) {
            unsigned char *buff = malloc(sz);
            unsigned char *p = buff;
            uint32_t left = sz;
            while (left) {
                long rc =recv(sock, p, left,0);
                if (rc==0) {
                    output("SOCKET_RECV_TRUNCATED");//Reply was truncated, expected %d more bytes
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
static NSDictionary *socket_send_xml(int sock,NSDictionary *message)
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

static BOOL is_file_exist(NSString *path)
{
    BOOL dir=NO;
    NSFileManager *fm=[NSFileManager defaultManager];
    BOOL exist=[fm fileExistsAtPath:path isDirectory:&dir];
    return exist;
}

static NSString *get_udid(struct am_device *device)
{
    CFStringRef identifier=AMDeviceCopyDeviceIdentifier(device);
    NSString *udid=CFBridgingRelease(identifier);
    return udid;
}

void install_app(struct am_device *device,NSString* app_path)
{
    die(is_file_exist(app_path), "FILE_NOT_EXIST");
    NSURL *file_url=[NSURL fileURLWithPath:app_path];
    NSDictionary *dict=@{ @"PackageType" : @"Developer" };
    CFURLRef local_app_url=CFBridgingRetain(file_url);
    CFDictionaryRef options = CFBridgingRetain(dict);
    die(!AMDeviceSecureTransferPath(0, device, local_app_url, options, NULL, 0), "!AMDeviceSecureTransferPath");
    die(!AMDeviceSecureInstallApplication(0, device, local_app_url, options, NULL, 0), "!AMDeviceSecureInstallApplication");
    CFBridgingRelease(options);
    CFBridgingRelease(local_app_url);
    success("OK");
}
void uninstall_app(struct am_device *device,NSString *app_id)
{
    CFStringRef bundle_id=CFBridgingRetain(app_id);
    die(!AMDeviceSecureUninstallApplication(0, device, bundle_id, 0, NULL, 0), "!AMDeviceSecureUninstallApplication");
    CFBridgingRelease(bundle_id);
    success("OK");
}

void install_mc(struct am_device *device,NSString *mc_path)
{
    die(is_file_exist(mc_path), "FILE_NOT_EXIST");
    int sock=start_service(device,@"com.apple.mobile.MCInstall");
    socket_send_xml(sock, @{@"RequestType":@"Flush"});
    NSData *payload=[NSData dataWithContentsOfFile:mc_path];
    socket_send_xml(sock, @{@"RequestType":@"InstallProfile", @"Payload": payload});
    success("OK");
}
void uninstall_mc(struct am_device *device, NSString *mc_id)
{
    die(0, "NOT_IMPLEMENT");
    int sock=start_service(device,@"com.apple.mobile.MCInstall");
    socket_send_xml(sock, @{@"RequestType":@"Flush"});
    socket_send_xml(sock, @{@"RequestType":@"RemoveProfile", @"Identifier": mc_id});
    success("OK");
}
void list_mc(struct am_device *device)
{
    int sock=start_service(device,@"com.apple.mobile.MCInstall");
    socket_send_xml(sock, @{@"RequestType":@"Flush"});
    NSDictionary *dict=socket_send_xml(sock, @{@"RequestType":@"GetProfileList"});
    NSString *o=[dict description];
    success(o.UTF8String);
}

void list_device()
{
    NSArray *udids=[devices allObjects];
    NSString *o=[udids componentsJoinedByString:@"\n"];
    success(o.UTF8String);
}

void on_device_connected(struct am_device *device)
{
    NSString *s=get_udid(device);
    NSString *o=[NSString stringWithFormat:@"CONNECTED %@",s];
    output(o.UTF8String);
    execute_on_device(device);
}

void on_device_disconnected(struct am_device *device)
{
    NSString *s=get_udid(device);
    NSString *o=[NSString stringWithFormat:@"DISCONNECTED %@",s];
    output(o.UTF8String);
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
        if (cookie) {
            on_device_connected(device);
        }
    }
    if (info->msg == ADNCI_MSG_DISCONNECTED)
    {
        NSString *s=get_udid(device);
        [devices removeObject:s];
        if (cookie) {
            on_device_disconnected(device);
        }
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

void execute_on_device(struct am_device *device)
{
    if (!(args.count<4)) {
        NSString *device_udid=args[3];
        NSString *udid=get_udid(device);
        if (![device_udid isEqualToString:udid]) {
            return;
        }
    }

    NSString *cmd=args[1];
    NSString *param=args[2];

    connect_to_device(device);

    if ([cmd isEqualToString:@"install_app"]) {
        install_app(device, param);
    }
    if ([cmd isEqualToString:@"uninstall_app"]) {
        uninstall_app(device, param);
    }
    if ([cmd isEqualToString:@"install_mc"]) {
        install_mc(device, param);
    }
    if ([cmd isEqualToString:@"list_mc"]) {
        list_mc(device);
    }

    disconnect_from_device(device);
}

int main(int argc, const char * argv[]) {
    NSMutableArray *arr=[NSMutableArray array];
    for (int i=0; i<argc; i++) {
        NSString *obj=[NSString stringWithUTF8String:argv[i]];
        [arr addObject:obj];
    }
    args=arr;

    if (args.count<2) {
        die(0, "command: [list_udid|install_app|uninstall_app|install_mc]");
    }
    devices=[NSMutableSet set];

    NSString *cmd=args[1];
    if ([cmd isEqualToString:@"list_udid"]) {
        register_device_notification(0);
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 3, NO);
        unregister_device_notification();
        list_device();
    }else{
        register_device_notification(1);
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 30, NO);
        unregister_device_notification();
        die(0, "DEVICE_NOT_FOUND");
    }

    return EXIT_SUCCESS;
}
