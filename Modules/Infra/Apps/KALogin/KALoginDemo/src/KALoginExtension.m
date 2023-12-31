//
//  KALoginExtension.m
//  KALoginDemo
//
//  Created by bytedance on 2021/12/20.
//

#import "KALoginExtension.h"
#import "KASSOViewController.h"
@import LKNativeAppExtensionAbility;

@interface KALoginExtension ()<LKNativeAppExtensionPageRoute>

@end

@implementation KALoginExtension

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (void)destroy {
    [super destroy];
}

- (NSString *)appId {
    return @"cli_766582753";
}

#pragma mark - LKNativeAppExtensionPageRoute

- (void)pageRoute: (NSURL *)link from:(UIViewController *)from {
    NSURLComponents *components =  [[NSURLComponents alloc] initWithString:link.absoluteString];
    __block NSString *redirectUrl;
    [components.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString: @"service"]) {
            redirectUrl = [obj.value copy];
            *stop = YES;
        }
    }];
    KASSOViewController *ssoVC = [[KASSOViewController alloc] initWithRedirectUrl:redirectUrl];
    [from presentViewController:ssoVC animated:YES completion:NULL];
}

@end
