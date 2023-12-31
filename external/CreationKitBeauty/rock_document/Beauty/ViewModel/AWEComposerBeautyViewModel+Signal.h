//
//  AWEComposerBeautyViewModel+Signal.h
//  CameraClient-Pods-Aweme
//
//  Created by ZhangYuanming on 2020/6/13.
//

#import <CreationKitBeauty/AWEComposerBeautyViewModel.h>
#import <ReactiveObjC/RACSignal.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEComposerBeautyViewModel (Signal)

@property (nonatomic, strong, readonly) RACSignal<AWEComposerBeautyEffectCategoryWrapper *> *currentCategorySignal;
@property (nonatomic, strong, readonly) RACSignal<AWEComposerBeautyEffectWrapper *> *selectedEffectSignal;

@end

NS_ASSUME_NONNULL_END
