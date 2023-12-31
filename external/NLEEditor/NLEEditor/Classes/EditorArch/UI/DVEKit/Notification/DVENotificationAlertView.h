//
//  DVENotificationAlertView.h
//  NLEEditor
//
//  Created by bytedance on 2021/8/9.
//

#import <UIKit/UIKit.h>
#import "DVENotificationView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVENotificationAlertView : DVENotificationView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;

@property (nonatomic, copy) DVEActionBlock leftActionBlock;
@property (nonatomic, copy) DVEActionBlock rightActionBlock;

/// 更新UI的布局（建议设置文本后，再调用）
- (void)updateUILayout;

@end

NS_ASSUME_NONNULL_END
