//
//  DVEBundleLoader.h
//  TTVideoEditorDemo
//
//  Created by bytedance on 2020/12/20
//  Copyright © 2021 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVEEffectValue.h"
#import "DVEEffectCategory.h"
#import "DVETextReaderModelProtocol.h"
#import "DVEResourceLoaderProtocol.h"

NS_ASSUME_NONNULL_BEGIN
@class DVEVCContext;

@interface DVEBundleLoader : NSObject

typedef void (^DVEModuleCategoryHandler)(NSArray<DVEEffectCategory*>* _Nullable categorys,NSString* _Nullable error);
typedef void (^DVEModuleModelHandler)(NSArray<DVEEffectValue*>* _Nullable datas,NSString* _Nullable error);

typedef void (^DVEModuleTextReaderModelHandler)(NSArray<id<DVETextReaderModelProtocol>>* _Nullable datas, NSError* _Nullable error);

+ (instancetype)shareManager;

//画布比例列表
- (void)canvasRatio:(DVEVCContext *)context handler:(DVEModuleModelHandler)hander;
///调节资源列表
- (void)adjust:(DVEVCContext *)context handler:(DVEModuleModelHandler)hander;
///入场动画资源列表
- (void)animationIn:(DVEVCContext*)context handler:(DVEModuleModelHandler)hander;
///出场动画资源列表
- (void)animationOut:(DVEVCContext*)context handler:(DVEModuleModelHandler)hander;
///组合动画资源列表
- (void)animationCombin:(DVEVCContext*)context handler:(DVEModuleModelHandler)hander;

- (void)filter:(DVEVCContext*)context handler:(DVEModuleModelHandler)hander;
- (void)sticker:(DVEVCContext *)context handler:(DVEModuleModelHandler)hander;
- (void)textAlign:(DVEVCContext*)context handler:(DVEModuleModelHandler)hander;
- (void)textFont:(DVEVCContext*)context handler:(DVEModuleModelHandler)hander;
- (void)textColor:(DVEVCContext*)context handler:(DVEModuleModelHandler)hander;
- (void)textStyle:(DVEVCContext*)context handler:(DVEModuleModelHandler)hander;
- (void)textAnimation:(DVEVCContext *)context
                 type:(DVEAnimationType)type
              handler:(DVEModuleModelHandler)hander;
- (void)stickerAnimation:(DVEVCContext *)context
                    type:(DVEAnimationType)type
                 handler:(DVEModuleModelHandler)hander;
- (void)transition:(DVEVCContext*)context handler:(DVEModuleModelHandler)hander;
- (void)mask:(DVEVCContext*)context handler:(DVEModuleModelHandler)hander;
- (void)effectCategory:(DVEVCContext *)context handler:(DVEModuleCategoryHandler)hander;
- (void)effect:(DVEVCContext *)context category:(DVEEffectCategory*)category handler:(DVEModuleModelHandler)hander;

- (void)textTemplateCategory:(DVEVCContext *)context handler:(DVEModuleCategoryHandler)hander;
- (void)textTemplate:(DVEVCContext *)context category:(DVEEffectCategory*)category handler:(DVEModuleModelHandler)hander;
- (void)flowerText:(DVEVCContext*)context handler:(DVEModuleModelHandler)hander;
- (void)mixedEffect:(DVEVCContext *)context handler:(DVEModuleModelHandler)hander;
- (void)textReaderSoundEffectList:(DVEVCContext*)context
                          handler:(DVEModuleTextReaderModelHandler)handler;
- (void)canvasStyleEffectList:(DVEVCContext*)context
                      handler:(DVEModuleModelHandler)handler;
- (void)curveSpeed:(DVEVCContext *)context handler:(DVEModuleModelHandler)handler;
/// 文字气泡
- (void)textBubble:(DVEVCContext*)context handler:(DVEModuleModelHandler)hander;
///变声
- (void)audioChange:(DVEVCContext*)context handler:(DVEModuleModelHandler)hander;

- (void)liteFilterCategory:(DVEVCContext *)context
                   handler:(DVEModuleCategoryHandler)hander;

- (void)liteFilter:(DVEVCContext *)context
          category:(DVEEffectCategory *)category
           handler:(DVEModuleModelHandler)hander;

- (void)liteBeauty:(DVEVCContext *)context
           handler:(DVEModuleModelHandler)handler;

- (void)liteEmojiSticker:(DVEVCContext *)context handler:(DVEModuleModelHandler)handler;

@end

NS_ASSUME_NONNULL_END
