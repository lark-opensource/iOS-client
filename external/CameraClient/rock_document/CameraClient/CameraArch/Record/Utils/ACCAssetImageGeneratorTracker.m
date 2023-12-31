//
//  ACCAssetImageGeneratorTracker.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/3/25.
//

#import "ACCAssetImageGeneratorTracker.h"
#import <CreativeKit/ACCTrackProtocol.h>

@interface ACCAssetImageGeneratorTracker ()
@property (nonatomic, strong) NSMutableArray *clipDurationArray;
@end


@implementation ACCAssetImageGeneratorTracker

+ (void)trackAssetImageGeneratorWithType:(ACCAssetImageGeneratorType)type
                                  frames:(NSInteger)count
                               beginTime:(NSTimeInterval)begin
                                   extra:(NSDictionary *)extraDic
{
    if (!count || !begin) {
        return;
    }
    
    NSMutableDictionary *params = extraDic ? extraDic.mutableCopy:@{}.mutableCopy;
    params[@"scene"] = [ACCAssetImageGeneratorTracker getSceneOfType:type];
    params[@"count"] = @(count);
    params[@"duration"] = @((NSInteger)((CFAbsoluteTimeGetCurrent() - begin) * 1000));
    [ACCTracker() trackEvent:@"tool_performance_fetch_frames" params:params.copy needStagingFlag:NO];
}

+ (void)trackAssetImageGeneratorWithType:(ACCAssetImageGeneratorType)type
                               durations:(NSArray<NSNumber *> *)generatorDurationArray
                                   extra:(NSDictionary *)extraDic
{
    if (![generatorDurationArray count]) {
        return;
    }
    
    NSMutableDictionary *params = extraDic ? extraDic.mutableCopy:@{}.mutableCopy;
    params[@"scene"] = [ACCAssetImageGeneratorTracker getSceneOfType:type];
    params[@"count"] = @([generatorDurationArray count]);
    __block NSTimeInterval duration = 0.f;
    [generatorDurationArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        duration += [obj doubleValue];
    }];
    params[@"duration"] = @((NSInteger)(duration * 1000));
    [ACCTracker() trackEvent:@"tool_performance_fetch_frames" params:params.copy needStagingFlag:NO];
}

+ (NSString *)getSceneOfType:(ACCAssetImageGeneratorType)type
{
    NSString *scene = @"";
    switch (type) {
        case ACCAssetImageGeneratorTypeClipSlider:
            scene = @"video_clip";
            break;
        case ACCAssetImageGeneratorTypeCoverChoose:
            scene = @"choose_cover";
            break;
        case ACCAssetImageGeneratorTypeStickerSelectTime:
            scene = @"sticker_select_time";
            break;
        case ACCAssetImageGeneratorTypeSpecialEffects:
            scene = @"special_effects";
            break;
        case ACCAssetImageGeneratorTypeAIMusic:
            scene = @"ai_music";
            break;
        default:
            break;
    }
    return scene;
}

@end
