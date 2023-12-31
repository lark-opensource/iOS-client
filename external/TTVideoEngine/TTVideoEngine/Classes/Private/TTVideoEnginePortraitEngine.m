//
//  TTVideoEnginePortraitEngine.m
//  TTVideoEngine
//
//  Created by bytedance on 2022/9/23.
//

#import <Foundation/Foundation.h>
#import "TTVideoEnginePortraitEngine.h"

@implementation TTVideoEnginePortraitEngine

+ (nonnull instancetype)instance {
    static dispatch_once_t onceToken;
    static TTVideoEnginePortraitEngine *_instance = nil;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (nonnull instancetype)init {
    if (self = [super init]) {
        _labelMap = [NSMutableDictionary new];
    }
    return self;
}

- (void)setLabel:(nullable id)value withKey:(nullable NSString *)key {
    
}
- (nullable id)getLabel:(nullable NSString *)key {
    return nil;
}

- (nullable id)getEventData:(nullable NSString *)type {
    return nil;
}

@end
