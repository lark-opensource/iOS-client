//
//  WKWebView+BDSecureLink.m
//  BDWebKit
//
//  Created by bytedance on 2020/4/17.
//

#import "WKWebView+BDSecureLink.h"
#import "NSObject+BDWRuntime.h"
#import <ByteDanceKit/NSObject+BTDAdditions.h>

@implementation WKWebView (BDSecureLink)

-(BOOL)bdw_pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL inside = [self bdw_pointInside:point withEvent:event];
    if (inside && ![self bdw_hasClick]) {
        [self setBdw_hasClick:YES];
    }
    
    return inside;
}

- (void)setBdw_hasClick:(BOOL)hasClick {
    [self bdw_attachObject:@(hasClick) forKey:@"bdw_hasClick"];
}

- (BOOL)bdw_hasClick {
    return [[self bdw_getAttachedObjectForKey:@"bdw_hasClick"] boolValue];
}

- (void)setBdw_secureLinkCheckRedirectType:(BDSecureLinkCheckRedirectType)bdw_secureLinkCheckRedirectType {
    [self bdw_attachObject:@(bdw_secureLinkCheckRedirectType) forKey:@"bdw_secureLinkCheckRedirectType"];
}

- (BDSecureLinkCheckRedirectType)bdw_secureLinkCheckRedirectType {
    return (BDSecureLinkCheckRedirectType)[[self bdw_getAttachedObjectForKey:@"bdw_secureLinkCheckRedirectType"] intValue];
}

- (void)setBdw_switchOnFirstRequestSecureCheck:(BOOL)bdw_switchOnFirstRequestSecureCheck {
    [self bdw_attachObject:@(bdw_switchOnFirstRequestSecureCheck) forKey:@"bdw_switchOnFirstRequestSecureCheck"];
}

- (BOOL)bdw_switchOnFirstRequestSecureCheck {
    return [[self bdw_getAttachedObjectForKey:@"bdw_switchOnFirstRequestSecureCheck"] boolValue];
}

- (void)setBdw_strictMode:(BOOL)bdw_strictMode {
    [self bdw_attachObject:@(bdw_strictMode) forKey:@"bdw_strictMode"];
    if (bdw_strictMode) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [self.class btd_swizzleInstanceMethod:@selector(pointInside:withEvent:) with:@selector(bdw_pointInside:withEvent:)];
        });
    }

}

- (BOOL)bdw_strictMode {
    return [[self bdw_getAttachedObjectForKey:@"bdw_strictMode"] boolValue];
}

- (void)setBdw_secureCheckHostAllowList:(NSArray *)bdw_secureCheckHostWhiteList {
    [self bdw_attachObject:bdw_secureCheckHostWhiteList forKey:@"bdw_secureCheckHostWhiteList"];
}

- (NSArray *)bdw_secureCheckHostAllowList {
    return [self bdw_getAttachedObjectForKey:@"bdw_secureCheckHostWhiteList"];
}

@end
