//
//  BDUGDialogBaseView.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/14.
//

#import <UIKit/UIKit.h>


@interface BDUGDialogBaseView : UIView

typedef void(^BDUGDialogViewBaseEventHandler)(BDUGDialogBaseView *dialogView);
/**
 多选项按钮确认回调
 
 @param dialogView 弹窗实例
 @param selectedIndex 选项索引
 */
typedef void(^BDUGDialogViewBaseActionHandler)(BDUGDialogBaseView *dialogView, NSInteger selectedIndex);

- (instancetype)initDialogViewWithTitle:(NSString *)title
                         confirmHandler:(BDUGDialogViewBaseEventHandler)confirmHandler
                          cancelHandler:(BDUGDialogViewBaseEventHandler)cancelHandler;

- (instancetype)initDialogViewWithTitle:(NSString *)title
                            buttonColor:(UIColor *)buttonColor
                         confirmHandler:(BDUGDialogViewBaseEventHandler)confirmHandler
                          cancelHandler:(BDUGDialogViewBaseEventHandler)cancelHandler;

- (void)addDialogContentView:(UIView *)contentView;

- (void)setContainerViewColor:(UIColor *)color;

- (void)show;

- (void)hide;

@end

