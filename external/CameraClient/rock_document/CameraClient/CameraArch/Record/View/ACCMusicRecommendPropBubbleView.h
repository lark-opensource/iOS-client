//
//  ACCMusicRecommendPropBubbleView.h
//  CameraClient-Pods-Aweme
//
//  Created by Lincoln on 2020/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;

typedef void(^ACCUseRecommendPropBlock)(IESEffectModel * _Nullable);

@interface ACCMusicRecommendPropBubbleView : UIView

- (instancetype)initWithPropModel:(IESEffectModel *)propModel
                     usePropBlock:(ACCUseRecommendPropBlock)usePropBlock;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
