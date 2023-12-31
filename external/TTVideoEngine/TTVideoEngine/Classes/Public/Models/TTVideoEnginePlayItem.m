//
//  TTVideoEnginePlayItem.m
//  Pods
//
//  Created by guikunzhi on 2017/5/23.
//
//

#import "TTVideoEnginePlayItem.h"
#import "NSObject+TTVideoEngine.h"

@implementation TTVideoEnginePlayItem
/// Please use @property.

- (instancetype)init {
    if (self = [super init]) {
        _resolution = TTVideoEngineResolutionTypeSD;
    }
    return self;
}

- (BOOL)isExpired {
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    if (time > self.expire) {
        return YES;
    }
    return NO;
}

///MARK: - NSSecureCoding

TTVIDEOENGINE_NSSECURECODING_IMPLEMENTATON

- (NSString *)description {
    return [self ttvideoengine_debugDescription];
}

@end
