//
//  ACCStickerDisplayManager.h
//  CameraClient-Pods-Aweme
//  非编辑链路下的贴纸展示工具，定义了最基本的行为，实现了最基本的能力
//  Created by 卜旭阳 on 2021/1/7.
//

#import <Foundation/Foundation.h>
#import "ACCStickerBizDefines.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerContentProtocol;
@class ACCStickerContainerView, AWEInteractionStickerModel, ACCDisplayStickerConfig;

@interface ACCStickerDisplayManager : NSObject

@property (nonatomic, weak, readonly) ACCStickerContainerView *stickerContainer;
@property (nonatomic, assign) CGRect targetContainerRect;
@property (nonatomic, assign) CGRect targetPlayerFrame;

// 与StickerContainer绑定
- (instancetype)initWithStickerContainer:(ACCStickerContainerView *)stickerContainer;
// 添加多个仅作展示的贴纸
- (void)displayWithModels:(NSArray<AWEInteractionStickerModel *> *)models;

// 向容器添加一个贴纸,基本能力
+ (void)displayStickerContentView:(UIView<ACCStickerContentProtocol> *)contentView
                           config:(ACCDisplayStickerConfig *)config
                            model:(AWEInteractionStickerModel *)model
                      inContainer:(ACCStickerContainerView *)containerView;

@end

NS_ASSUME_NONNULL_END
