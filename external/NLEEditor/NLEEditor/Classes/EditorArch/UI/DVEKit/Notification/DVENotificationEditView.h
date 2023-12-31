//
//  DVENotificationEditView.h
//  NLEEditor
//
//  Created by bytedance on 2021/10/20.
//

#import <UIKit/UIKit.h>
#import "DVENotificationView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVENotificationEditView : DVENotificationView

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *editText;
@property (nonatomic, strong) UIView *onLine;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;

@property (nonatomic, copy) DVEActionBlock leftActionBlock;
@property (nonatomic, copy) DVEActionBlock rightActionBlock;

- (void)showEditTextLimit:(NSUInteger)limitLength;

@end

NS_ASSUME_NONNULL_END
