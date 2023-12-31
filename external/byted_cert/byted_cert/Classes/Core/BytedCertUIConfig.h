//
//  BytedCertUIConfig.h
//  BytedCert
//
//  Created by LiuChundian on 2019/3/23.
//  Copyright © 2019年 bytedance. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 *  活体检测UI适配
 *
 *  backgroundColor     背景色
 *  textColor           文字颜色
 *  timeColor           倒计时圈的颜色
 *  circleColor         圆圈的底色
 *  backBtnImageName    返回按钮的图片名
 */
@interface BytedCertUIConfig : NSObject

+ (instancetype _Nonnull)sharedInstance;

@property (nonatomic, assign) UIStatusBarStyle statusBarStyle;

@property (nonatomic, strong, nullable) UIColor *primaryColor;
@property (nonatomic, strong, nullable) UIColor *backgroundColor;
@property (nonatomic, strong, nullable) UIColor *secondBackgroundColor;
@property (nonatomic, strong, nullable) UIColor *textColor;
@property (nonatomic, strong, nullable) UIColor *secondTextColor;

@property (nonatomic, strong, nullable) UIColor *timeColor;
@property (nonatomic, strong, nullable) UIColor *circleColor;

@property (nonatomic, strong, nullable) UIFont *actionLabelFont;
@property (nonatomic, strong, nullable) UIFont *readNumberLabelFont;
@property (nonatomic, strong, nullable) UIFont *actionCountTipLabelFont;

@property (nonatomic, assign) CGFloat faceDetectionProgressStrokeWidth;
@property (nonatomic, strong, nullable) UIImage *faceDetectionBgImage;
@property (nonatomic, strong, nullable) UIImage *backBtnImage;

@property (nonatomic, assign) BOOL isDarkMode;

@end


@interface BytedCertUIConfigMaker : NSObject

/// APP 主题色 用户人脸倒计时进度条
- (BytedCertUIConfigMaker *_Nonnull (^_Nonnull)(UIColor *_Nullable))primaryColor;
- (BytedCertUIConfigMaker *_Nonnull (^_Nonnull)(UIColor *_Nullable))backgroundColor;
- (BytedCertUIConfigMaker *_Nonnull (^_Nonnull)(UIColor *_Nullable))secondBackgroundColor;
- (BytedCertUIConfigMaker *_Nonnull (^_Nonnull)(UIColor *_Nullable))textColor;
- (BytedCertUIConfigMaker *_Nonnull (^_Nonnull)(UIColor *_Nullable))secondTextColor;

/// 活体动作提示字号
- (BytedCertUIConfigMaker *_Nonnull (^_Nonnull)(UIFont *_Nullable))actionLabelFont;
- (BytedCertUIConfigMaker *_Nonnull (^_Nonnull)(UIFont *_Nullable))actionCountTipLabelFont;

- (BytedCertUIConfigMaker *_Nonnull (^_Nonnull)(UIImage *_Nullable))faceDetectionBgImage;
- (BytedCertUIConfigMaker *_Nonnull (^_Nonnull)(UIImage *_Nullable))backBtnImage;

- (BytedCertUIConfigMaker *_Nonnull (^_Nonnull)(BOOL))isDarkMode;

@end
