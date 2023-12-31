//
//  MODUserServiceImpl.m
//  CameraClient
//
//  Created by haoyipeng on 2021/11/1.
//  Copyright © 2021 chengfei xiao. All rights reserved.
//

#import "MODUserServiceImpl.h"

@implementation MODUserServiceImpl

- (nonnull id<ACCUserModelProtocol>)currentLoginUserModel {
    return nil;
}

- (void)getUserProfileWithID:(nonnull NSString *)userID secUserID:(nonnull NSString *)secUserID completion:(nonnull void (^)(id<ACCUserModelProtocol> _Nonnull, NSError * _Nonnull))completion {
    
}

- (BOOL)isChildMode {
    return NO;
}

- (BOOL)isCurrentLoginUserWithID:(nonnull NSString *)userID {
    return NO;
}

- (BOOL)isLogin {
    return YES;
}

- (BOOL)isNewUser {
    return NO;
}

- (void)requireLogin:(nonnull void (^)(BOOL))completion {
    if (completion) {
        completion(YES);
    }
}

- (void)requireLogin:(nonnull void (^)(BOOL))completion withTrackerInformation:(nonnull NSDictionary *)trackerInformation {
    if (completion) {
        completion(YES);
    }
}

@synthesize isUserLogin = _isUserLogin;

@end
