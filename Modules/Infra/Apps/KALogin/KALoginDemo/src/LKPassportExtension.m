//
//  LKPassportExtension.m
//  KALogin
//
//  Created by bytedance on 2021/12/21.
//

#import "LKPassportExtension.h"
@import LKNativeAppExtensionAbility;
@import KALogin;

@interface LKPassportExtension ()<LKNativeAppExtensionPageRoute>

@end

@implementation LKPassportExtension

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (void)destroy {
    [super destroy];
}

- (NSString *)appId {
    return @"cli_7665827532";
}

#pragma mark - LKNativeAppExtensionPageRoute

- (void)pageRoute: (NSURL *)link from:(UIViewController *)from {
    KALoginLandingViewController *landVC = [[KALoginLandingViewController alloc] initWithLandURL:link.absoluteString from: from];
    [from presentViewController:landVC animated:YES completion:NULL];
}

@end
