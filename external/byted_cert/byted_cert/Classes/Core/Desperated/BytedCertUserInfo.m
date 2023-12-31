//
//  BytedCertUserInfo.m
//  BytedCert
//
//  Created by LiuChundian on 2019/6/2.
//

#import <Foundation/Foundation.h>
#import "BytedCertUserInfo.h"
#import "BytedCertManager+Private.h"


@interface BytedCertUserInfo ()

@end


@implementation BytedCertUserInfo

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static BytedCertUserInfo *userInfo = nil;

    dispatch_once(&onceToken, ^{
        userInfo = [[BytedCertUserInfo alloc] init];
    });
    return userInfo;
}

- (NSString *)ticket {
    return BytedCertManager.shareInstance.latestTicket;
}

@end
