//
//  AWEComposerBeautyViewModel+Signal.m
//  CameraClient-Pods-Aweme
//
//  Created by ZhangYuanming on 2020/6/13.
//

#import <CreationKitBeauty/AWEComposerBeautyViewModel+Signal.h>
#import <ReactiveObjC/NSObject+RACPropertySubscribing.h>

@implementation AWEComposerBeautyViewModel (Signal)

#pragma mark - Signal

- (RACSignal<AWEComposerBeautyEffectCategoryWrapper *> *)currentCategorySignal
{
    return RACObserve(self, currentCategory);
}

- (RACSignal<AWEComposerBeautyEffectWrapper *> *)selectedEffectSignal
{
    return RACObserve(self, selectedEffect);
}

@end
