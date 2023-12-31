//
//  AWEStickerPickerDelegate.h
//  AWEFoundation
//
//  Created by bingliu on 1/7/18.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/AWEComposerEffectProtocol.h>

@class IESEffectModel;

typedef void(^AWEApplyStickerCompletionBlock)(BOOL success, NSInteger stickerId, NSString *resourcePath);

typedef void(^AWEModernRecordStickerVCDismissBlock)(IESEffectModel *sticker);

@protocol AWEModernStickerPickerDelegate <NSObject>

- (void)applySticker:(IESEffectModel *)item completion:(AWEApplyStickerCompletionBlock)completion;
// 单纯对ve设置道具接口的封装，无额外逻辑
- (void)applyVESticker:(IESEffectModel *)item;
- (void)applyComposerSticker:(id<AWEComposerEffectProtocol>)item extra:(NSString *)extra;
// 单纯对ve设置composer道具接口的封装，无额外逻辑
- (void)applyVEComposerSticker:(id<AWEComposerEffectProtocol>)item extra:(NSString *)extra;
- (void)invokeFaceDetectingProgress:(IESEffectModel *)item completion:(AWEApplyStickerCompletionBlock)completion;

@optional
- (void)didChooseImage:(UIImage *)image;

@end

@protocol AWEModernStickerPicker <NSObject>

@property (nonatomic, copy) AWEModernRecordStickerVCDismissBlock dismissBlock;

- (void)showOnViewController:(UIViewController *)controller;

@end
