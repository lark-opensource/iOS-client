//
//  TSPKScreenRecorderOfRPSystemBroadcastPickerViewPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKScreenRecorderOfRPSystemBroadcastPickerViewPipeline.h"
#import <ReplayKit/RPBroadcast.h>
#import "NSObject+TSAddition.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation RPSystemBroadcastPickerView (TSPrivacyKitScreenRecorder)

+ (void)tspk_screen_record_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKScreenRecorderOfRPSystemBroadcastPickerViewPipeline class] clazz:self];
}

- (instancetype)tspk_screen_record_init
{
    
    TSPKHandleResult *result = [TSPKScreenRecorderOfRPSystemBroadcastPickerViewPipeline handleAPIAccess:NSStringFromSelector(@selector(init)) className:[TSPKScreenRecorderOfRPSystemBroadcastPickerViewPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else {
        return [self tspk_screen_record_init];
    }
}

@end

@implementation TSPKScreenRecorderOfRPSystemBroadcastPickerViewPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineScreenRecorderOfRPSystemBroadcastPickerView;
}

+ (TSPKStoreType)storeType
{
    return TSPKStoreTypeRelationObjectCache;
}

+ (NSString *)dataType {
    return TSPKDataTypeScreenRecord;
}

+ (NSString *)stubbedClass
{
    if (@available(iOS 12.0, *)) {
        return @"RPSystemBroadcastPickerView";
    }
    return nil;
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(init))
    ];
}

+ (void)preload
{
    if (@available(iOS 12.0, *)) {
        [RPSystemBroadcastPickerView tspk_screen_record_preload];
    }
}

@end
