//
//  ACCEditBeautyProtocol.h
//  CameraClient
//
//  Created by zhangyuanming on 2021/1/20.
//

#import "ACCEditWrapper.h"
#import <EffectPlatformSDK/IESEffectModel.h>

// FIXME: @haoyipeng use forward declaration temporarily, as BeautySDK has not sink to CreationKit
@class AWEComposerBeautyEffectWrapper;
@class AWEComposerBeautyEffectItem;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditBeautyProtocol <ACCEditWrapper>

//- (BOOL)replaceComposerNodesWithNewTag:(NSArray *)newNodes old:(NSArray *)oldNodes;
//- (void)appendComposerNodesWithTags:(NSArray *)nodes;
//- (void)removeComposerNodesWithTags:(NSArray *)nodes;
//- (BOOL)updateComposerNode:(NSString *)node key:(NSString *)key value:(CGFloat)value;
//
//@optional
- (void)replaceComposerBeauty:(AWEComposerBeautyEffectWrapper *)effectWrapper
                      withOld:(nullable AWEComposerBeautyEffectWrapper *)oldWrapper;

- (void)appendComposerBeautys:(NSArray<AWEComposerBeautyEffectWrapper *> *)effects;

- (void)removeBeautyEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effects;

- (void)updateBeautyEffectItem:(AWEComposerBeautyEffectItem *)item
                    withEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                         ratio:(float)ratio;

- (void)updateBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;

@end

NS_ASSUME_NONNULL_END
