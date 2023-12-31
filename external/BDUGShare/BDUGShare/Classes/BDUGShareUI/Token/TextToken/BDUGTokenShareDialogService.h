//
//  BDUGTokenShareDialogService.h
//  Article
//
//  Created by zengzhihui on 2018/5/31.
//
#import <Foundation/Foundation.h>
#import "BDUGTokenShareAnalysisResultCommom.h"

NS_ASSUME_NONNULL_BEGIN

@class BDUGTokenShareInfo;

@interface BDUGTokenShareServiceActionModel : NSObject

@property (nonatomic, copy, nullable) BDUGTokenTapActionHandler showHander;
@property (nonatomic, copy, nullable) BDUGTokenTapActionHandler actionHandler;
@property (nonatomic, copy, nullable) BDUGTokenTapActionHandler tiptapHandler;
@property (nonatomic, copy, nullable) BDUGTokenTapActionHandler cancelHandler;

@end

/*
 * 口令分享弹窗，由于UI样式依赖主端，所以不放在分享库里
 */
@interface BDUGTokenShareDialogService : NSObject

/**
 初始化口令识别服务。
 */
+ (void)registerService;

+ (void)registerServiceWithNotificationName:(NSString * _Nullable)notificationName;

/// 注册分析隐写图片成功后的按钮点击事件
/// @param actionModel 点击时间handler
+ (void)registerTokenShareWithActionModel:(BDUGTokenShareServiceActionModel *)actionModel;

/**
 设置主题颜色。【底部按钮颜色】
 
 @param themeColor 颜色
 */
+ (void)configThemeColor:(UIColor *)themeColor;

@end

NS_ASSUME_NONNULL_END
