//
//  TMAStickerInputView.h
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/17.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMAStickerInputModel.h"
#import <OPFoundation/BDPJSBridgeProtocol.h>

@class TMAStickerInputView;
@class TMAStickerInputModel;

typedef NS_ENUM (NSUInteger, TMAKeyboardType) {
    /// 收起键盘
    TMAKeyboardTypeNone = 0,
    /// 系统键盘
    TMAKeyboardTypeSystem,
    /// 表情
    TMAKeyboardTypeSticker,
    /// 图片
    TMAKeyboardTypePicture,
    /// @
    TMAKeyboardTypeAt,
};

typedef NS_ENUM(NSInteger, TMAStickerInputErrorType) {
    TMAStickerInputErrorTypeRequestOpenID
};

@protocol TMAStickerInputViewDelegate <NSObject>

@optional

#pragma mark sticker

- (BOOL)stickerInputViewShouldBeginEditing:(TMAStickerInputView *)inputView;

- (void)stickerInputViewDidEndEditing:(TMAStickerInputView *)inputView;

- (void)stickerInputViewDidChange:(TMAStickerInputView *)inputView;

- (void)stickerInputViewDidClickSendButton:(TMAStickerInputView *)inputView;

#pragma mark picture

@end

@interface TMAStickerInputView : UIView

@property (nonatomic, strong) TMAStickerInputModel *model;

@property (nonatomic, copy) void (^modelChangedBlock)(TMAStickerInputEventType type);

@property (nonatomic, copy) void (^onError)(TMAStickerInputErrorType errorType, TMAStickerInputEventType eventType);

@property (nonatomic, weak) id<TMAStickerInputViewDelegate> delegate;

@property (nonatomic, strong, readonly) NSString *plainText;

@property (nonatomic, assign, readonly) TMAKeyboardType keyboardType;

- (nonnull instancetype)initWithFrame:(CGRect)frame currentViewController:(UIViewController *)currentViewController model:(TMAStickerInputModel *)model uniqueID:(BDPUniqueID *)uniqueID;

- (CGFloat)heightThatFits;

- (void)collectDataWithType:(TMAStickerInputEventType)type uniqueID:(OPAppUniqueID *)uniqueID session:(NSString *)session sessionHandler:(NSDictionary *)sessionHandler completionBlock:(void (^)(void))completionBlock;

- (void)clearText;

- (void)changeKeyboardTo:(TMAKeyboardType)toType;

@end
