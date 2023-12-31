//
//  AWEComposerBeautyDataHandleProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by ZhangYuanming on 2020/6/2.
//

#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWEComposerBeautyDataHandleProtocol <NSObject>

- (BOOL)filterBeautyWithCategoryWrapper:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper;
- (BOOL)filterBeautyWithEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (NSInteger)currentABGroup;

@end

NS_ASSUME_NONNULL_END

