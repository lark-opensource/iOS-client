//
//  BDXLynxKitUtils.m
//  BDXLynxKit
//
//  Created by tianbaideng on 2021/3/10.
//

#import "BDXLynxKitUtils.h"
#import <UIKit/UIKit.h>

@implementation BDXLynxKitUtils

+ (void)toastErrorMessage:(NSString *)message forDuration:(NSInteger)duration
{
    //#pragma clang diagnostic push
    //#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIAlertView *toast = [[UIAlertView alloc] initWithTitle:nil message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [toast show];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [toast dismissWithClickedButtonIndex:0 animated:YES];
    });
    //#pragma clang diagnostic pop
}

+ (BOOL)isRelativeURL:(NSURL *)url
{
    NSArray *prefixArray = @[@"https://", @"data:/", @"res://", @"file://", @"content://"];

    BOOL isRelative = YES;
    NSString *urlString = url.absoluteString;
    for (NSString *prefix in prefixArray) {
        if ([urlString hasPrefix:prefix]) {
            isRelative = NO;
        }
    }
    return isRelative;
}

+ (BOOL)isResourceLoaderNotHandleURL:(NSURL *)url
{
    NSArray *prefixArray = @[@"data:", @"res://", @"file://", @"content://"];

    BOOL isResourceLoaderNotHandle = NO;
    for (NSString *prefix in prefixArray) {
        if ([url.absoluteString hasPrefix:prefix]) {
            isResourceLoaderNotHandle = YES;
        }
    }
    return isResourceLoaderNotHandle;
}

@end
