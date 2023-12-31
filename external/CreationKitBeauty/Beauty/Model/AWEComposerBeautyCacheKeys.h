//
//  AWEComposerBeautyCacheKeys.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/1/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEComposerBeautyCacheKeys : NSObject

@property (nonatomic, copy, readonly) NSString *effectSetCachePrefix;
@property (nonatomic, copy, readonly) NSString *categoryCachePrefix;
@property (nonatomic, copy, readonly) NSString *selectedChildCategoryCachePrefix;
@property (nonatomic, copy, readonly) NSString *effectConfigurationPrefix;
@property (nonatomic, copy, readonly) NSString *effectAppliedEffectsCacheKey;
@property (nonatomic, copy, readonly) NSString *categorySwitchOnKey;

@property (nonatomic, copy, readonly) NSString *appliedFilterPlaceHolder;
@property (nonatomic, copy, readonly) NSString *appliedFilterIDKey;
@property (nonatomic, copy, readonly) NSString *consecutiveRecognizedAsFemaleCountKey;
@property (nonatomic, copy, readonly) NSString *panelLastSelectedTabIDKey;
@property (nonatomic, copy, readonly) NSString *selectedTimeStampKey;

@property (nonatomic, copy, readonly) NSString *businessName;

// XS and DMT do not share the cache key, DMT is empty by default, other product settings
- (instancetype)initWithBusinessName:(NSString *)businessName;

@end

NS_ASSUME_NONNULL_END
