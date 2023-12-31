//
//  UIFont+EMA.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/21.
//

#import <UIKit/UIKit.h>

@interface UIFont (OP)

@property (class, nonatomic, readonly, nonnull) UIFont *op_text14;
@property (class, nonatomic, readonly, nonnull) UIFont *op_text12;
@property (class, nonatomic, readonly, nonnull) UIFont *op_text11;
+ (nonnull UIFont *)op_textWithSize:(CGFloat)size;

@property (class, nonatomic, readonly, nonnull) UIFont *op_title26;
@property (class, nonatomic, readonly, nonnull) UIFont *op_title20;
@property (class, nonatomic, readonly, nonnull) UIFont *op_title17;
@property (class, nonatomic, readonly, nonnull) UIFont *op_title16;
+ (nonnull UIFont *)op_titleWithSize:(CGFloat)size;

@end
