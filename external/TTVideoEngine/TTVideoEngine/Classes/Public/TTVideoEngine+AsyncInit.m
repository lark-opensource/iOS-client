//
//  TTVideoEngine+AsyncInit.m
//  TTVideoEngine
//
//  Created by haocheng on 2021/9/22.
//

#import "TTVideoEngine+AsyncInit.h"
#import "TTVideoEnginePlayerViewWrapper.h"

@implementation TTVideoEngine (AsyncInit)

+ (TTVideoEnginePlayerViewWrapper *)viewWrapperWithType:(TTVideoEnginePlayerType)type {
    TTVideoEnginePlayerViewWrapper *wrapper = [[TTVideoEnginePlayerViewWrapper alloc] initWithType:type];
    return wrapper;
}

@end
