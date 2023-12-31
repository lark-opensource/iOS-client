//
//   DVEEffectsBarBottomView.h
//   NLEEditor
//
//   Created  by bytedance on 2021/4/19.
//   Copyright © 2021 ByteDance Ltd. All rights reserved.
//
    

#import <UIKit/UIKit.h>
#import <DVEFoundationKit/DVEUIHelper.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEEffectsBarBottomView : UIView


/// 通过标题和点击事件构造Bar
/// @param title 标题
/// @param block 右侧按钮点击事件
+(instancetype)newActionBarWithTitle:(NSString*)title action:(dispatch_block_t) block;

///设置标题
-(void)setTitleText:(NSString*)text;
///标题
-(NSString*)titleText;
///设置点击事件
-(void)setActionBlcok:(dispatch_block_t __nullable)actionBlcok;
///设置重制事件
-(void)setupResetBlock:(dispatch_block_t __nullable)actionBlcok;
///设置重制按钮标题
-(void)setResetTitle:(NSString*)title;
///设置重制按钮icon
- (void)setResetIcon:(UIImage*)image;
/// 设置重制按钮状态
/// @param enable 是否可用
-(void)setResetButtonEnable:(BOOL)enable;
/**
 是否隐藏重置按钮
 */
- (void)setResetButtonHidden:(BOOL)isHidden;

@end

NS_ASSUME_NONNULL_END
