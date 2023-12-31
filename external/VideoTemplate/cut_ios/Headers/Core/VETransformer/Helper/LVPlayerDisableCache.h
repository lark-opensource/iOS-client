//
//  LVPlayerDisableCache.h
//  LVTemplate
//
//  Created by kevin gao on 2019/12/25.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LVPlayerFeatureType.h"

NS_ASSUME_NONNULL_BEGIN

@interface LVPlayerDisableCache : NSObject

@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*, NSNumber *>* disableFeautreFlipXMap;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*, NSNumber *>* disableFeautreFlipYMap;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*, NSNumber *>* disableFeautreBeautyMap;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*, NSNumber *>* disableFeautreChromaMap;
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*, NSNumber *>* disableFeautreSeparatedSoundMap;

/*
 注册禁用缓存
 */
- (void)disableFeatureType:(LVPlayerFeatureType)type segmentId:(NSString*)segmentId;

/*
 移除禁用缓存
 */
- (void)removeDisableFeatureType:(LVPlayerFeatureType)type segmentId:(NSString*)segmentId;

/*
 清除某一种类型
 */
- (void)clearDisableFeatureType:(LVPlayerFeatureType)type;

/*
 清空所有
 */
- (void)clear;

@end

NS_ASSUME_NONNULL_END
