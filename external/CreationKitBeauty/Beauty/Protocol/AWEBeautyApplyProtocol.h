//
//  AWEBeautyApplyProtocol.h
//  AWEStudio-Pods-Aweme
//
//  Created by ZhangYuanming on 2020/5/29.
//

#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>

@protocol AWEBeautyApplyProtocol <NSObject>

- (void)applyBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (void)updateBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (void)updateBeautyEffectItem:(AWEComposerBeautyEffectItem *)item
                    withEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                         ratio:(float)ratio;
- (void)removeBeautyEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effects;
- (void)applyComposerBeautyEffects:(NSArray <AWEComposerBeautyEffectWrapper *> *)effectWrappers;
- (void)replaceBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                    withOld:(AWEComposerBeautyEffectWrapper *)oldEffectWrapper;

@end
