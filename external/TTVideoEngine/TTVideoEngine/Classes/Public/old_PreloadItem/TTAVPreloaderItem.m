//
//  TTAVPreloaderItem.m
//  Pods
//
//  Created by 钟少奋 on 2017/4/11.
//
//

#import "TTAVPreloaderItem.h"
#import "TTVideoEngineModeldef.h"

@implementation TTAVPreloaderItem {
    NSArray *_supportedResolutionTypes;
}

- (NSArray<NSNumber *> *)supportedResolutionTypes {
    if (_supportedResolutionTypes) {
        return _supportedResolutionTypes;
    }
    
    NSMutableArray *types = [NSMutableArray array];
    int32_t mask = self.supportedResolutionMask;
    if (mask & (1<<1)) {
        [types addObject:@(TTVideoEngineResolutionTypeSD)];
    }
    if (mask & (1<<2)) {
        [types addObject:@(TTVideoEngineResolutionTypeHD)];
    }
    if (mask & (1<<3)) {
        [types addObject:@(TTVideoEngineResolutionTypeFullHD)];
    }
    if (mask & (1<<4)) {
        [types addObject:@(TTVideoEngineResolutionType1080P)];
    }
    if (mask & (1<<5)) {
        [types addObject:@(TTVideoEngineResolutionType4K)];
    }
    _supportedResolutionTypes = types.copy;
    return _supportedResolutionTypes;
}

@end
