//
//  UIApplication+IESGurdKit.m
//  IESGeckoKit
//
//  Created by xinwen tan on 2021/12/21.
//

#import "UIApplication+IESGurdKit.h"

@implementation UIApplication (IESGurdKit)

+ (NSNumber *)iesgurdkit_freeDiskSpace
{
    NSDictionary *fattributes = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error:nil];
    return [fattributes objectForKey:NSFileSystemFreeSize];
}

@end
