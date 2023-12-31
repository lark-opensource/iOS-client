//
//  AWEComposerBeautyEffectKeys.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/1/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const AWEComposerBeautyLastPanelNameKey;

@interface AWEComposerBeautyEffectKeys : NSObject

@property (nonatomic, copy, readonly) NSString *lastPanelNameKey;
@property (nonatomic, copy, readonly) NSString *lastABGroupKey;
@property (nonatomic, copy, readonly) NSString *lastRegionKey;
@property (nonatomic, copy, readonly) NSString *businessName;
@property (nonatomic, copy, readonly) NSString *userHadModifiedKey;

// XS and DMT do not share the cache key, DMT is empty by default, other product settings
- (instancetype)initWithBusinessName:(NSString *)businessName;

@end

NS_ASSUME_NONNULL_END
