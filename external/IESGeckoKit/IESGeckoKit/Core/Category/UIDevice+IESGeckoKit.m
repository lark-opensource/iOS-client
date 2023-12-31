//
//  UIDevice+IESGurdKit.m
//  IESGurdKit
//
//  Created by li keliang on 2019/3/7.
//

#import "UIDevice+IESGeckoKit.h"

#import <sys/utsname.h>
#import <sys/sysctl.h>

@implementation UIDevice (IESGurdKit)

+ (NSString *)ies_machineModel
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *machineModel = [NSString stringWithUTF8String:machine];
    free(machine);
    return machineModel;
}

@end
