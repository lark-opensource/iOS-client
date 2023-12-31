//
//  TMAStickerAvatarView.h
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/28.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMAStickerInputModel.h"

@class TMAStickerInputUserSelectModel;

@interface TMAStickerAvatarView : UIView

@property (nonatomic, strong, readonly) TMAStickerInputUserSelectModel *userSelectModel;

@property (nonatomic, copy) void (^modelChangedBlock)(TMAStickerInputEventType type);

- (instancetype)initWithFrame:(CGRect)frame currentViewController:(UIViewController *)currentViewController userModelSelectOpt:(BOOL)userModelSelectOpt;

- (void)configureViewsWithAvatarURL:(NSURL *)avatarURL userSelectModel:(TMAStickerInputUserSelectModel *)userSelectModel showPickerViewCompletionBlock:(void(^)(BOOL shows))showPickerViewCompletionBlock;

@end
