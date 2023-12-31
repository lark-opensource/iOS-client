//
//  BDUGImageShareDialogService.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/9.
//

#define BDUG_IMAGE_SHARE_SERVICE [BDUGImageShareDialogService sharedService]

#import <Foundation/Foundation.h>
#import "BDUGImageShare.h"
#import "BDUGTokenShareAnalysisResultCommom.h"
#import "BDUGTokenShareDialogService.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BDUGImageShareDialogServiceDelegate <NSObject>

/**
 相册权限弹窗展示
 */
- (void)imageShareAlbumAuthorizationDialogDidShowWithPanelID:(NSString * _Nullable)panelID;

/**
 相册权限弹窗点击
 
 @param confirm 是否开启相册权限
 */
- (void)imageShareAlbumAuthorizationDialogDidClick:(BOOL)confirm panelID:(NSString * _Nullable)panelID;

/**
 图片保存成功弹窗展示
 */
- (void)imageShareSaveSucceedDialogDidShowWithPanelID:(NSString * _Nullable)panelID;

/**
 图片保存成功弹窗点击
 
 @param confirm 是否继续分享到其他平台
 */
- (void)imageShareSaveSucceedDialogDidClick:(BOOL)confirm panelID:(NSString * _Nullable)panelID;

@end

@interface BDUGImageShareDialogService : NSObject

@property (nonatomic, weak, nullable) id <BDUGImageShareDialogServiceDelegate> delegate;

+ (instancetype)sharedService;

/**
 初始化图片识别服务, 默认不请求相册权限。
 */
+ (void)registerService;

/**
 初始化图片识别服务

 @param permissionAlert 是否立刻请求相册权限并分析相册隐写图片内容
 */
+ (void)registerServiceWithAlbumPermissionAlert:(BOOL)permissionAlert
                               notificationName:(NSString * _Nullable)notificationName;

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
