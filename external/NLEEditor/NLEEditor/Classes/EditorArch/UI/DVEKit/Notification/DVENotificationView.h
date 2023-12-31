//
//  DVENotificationView.h
//  NLEEditor
//
//  Created by bytedance on 2021/8/9.
//

#import <UIKit/UIKit.h>
#import "DVEAlertProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVENotificationView : UIView

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, copy) DVEActionBlock closeActionBlock;

- (void)setupUI NS_REQUIRES_SUPER;

/// 更新弹窗内容View高度
/// @param height 高度值
- (void)updateContentViewHeight:(CGFloat)height;

@end

NS_ASSUME_NONNULL_END
