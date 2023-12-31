//
//  ACCAssetImageGeneratorTracker.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/3/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCAssetImageGeneratorType) {
    ACCAssetImageGeneratorTypeUnKnown = 0,
    ACCAssetImageGeneratorTypeClipSlider,       //slider for video clip
    ACCAssetImageGeneratorTypeCoverChoose,      //slider for choose cover
    ACCAssetImageGeneratorTypeStickerSelectTime,//slider for sticker select time
    ACCAssetImageGeneratorTypeSpecialEffects,   //slider for special effects
    ACCAssetImageGeneratorTypeAIMusic,          //frames for AI music recommend
};


@interface ACCAssetImageGeneratorTracker : NSObject

+ (void)trackAssetImageGeneratorWithType:(ACCAssetImageGeneratorType)type
                                  frames:(NSInteger)count
                               beginTime:(NSTimeInterval)begin
                                   extra:(NSDictionary *)extraDic;

+ (void)trackAssetImageGeneratorWithType:(ACCAssetImageGeneratorType)type
                               durations:(NSArray<NSNumber *> *)generatorDurationArray
                                   extra:(NSDictionary *)extraDic;


@end

NS_ASSUME_NONNULL_END
