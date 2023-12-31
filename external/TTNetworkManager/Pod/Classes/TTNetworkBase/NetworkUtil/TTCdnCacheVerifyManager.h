//
//  TTCdnCacheVerifyManager.h
//  Created by changxing on 2019/10/28.
//
//  Cdn cache response verification，
//  It is used to identify whether the response comes from the real server,
//  if it is hijacked, it will report exception and report the user's buried point for monitoring and alarm.
//  Ralated Link: doc/doccnMxoPZFXNnbIh9ptsLOO6Vg
//
//
#import <Foundation/Foundation.h>

@interface TTCdnCacheVerifyManager : NSObject

+ (instancetype)shareInstance;

- (void)onConfigChange  :(BOOL)enabled
        data            :(NSDictionary *)data;

- (void)dealloc;

@end
