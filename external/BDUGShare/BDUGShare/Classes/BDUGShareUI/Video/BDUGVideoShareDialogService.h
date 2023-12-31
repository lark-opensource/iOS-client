//
//  BDUGImageShareDialogService.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDUGVideoShareDialogServiceDelegate <NSObject>

/**
 相册权限弹窗展示
 */
- (void)videoShareAlbumAuthorizationDialogDidShowWithPanelID:(NSString * _Nullable)panelID;

/**
 相册权限弹窗点击

 @param confirm 是否开启相册权限
 */
- (void)videoShareAlbumAuthorizationDialogDidClick:(BOOL)confirm panelID:(NSString * _Nullable)panelID;

/**
 引导弹窗展示
 */
- (void)videoSharePreviewDialogDidShowWithPanelID:(NSString * _Nullable)panelID;

/**
 引导弹窗点击

 @param confirm 是否继续保存视频并分享
 */
- (void)videoSharePreviewDialogDidClick:(BOOL)confirm panelID:(NSString * _Nullable)panelID;

/**
 视频保存成功弹窗展示
 */
- (void)videoShareSaveSucceedDialogDidShowWithPanelID:(NSString * _Nullable)panelID;

/**
 视频保存成功弹窗点击

 @param confirm 是否继续分享到其他平台
 */
- (void)videoShareSaveSucceedDialogDidClick:(BOOL)confirm panelID:(NSString * _Nullable)panelID;

@end

@interface BDUGVideoShareDialogService : NSObject

+ (instancetype)sharedService;

@property (nonatomic, weak, nullable) id <BDUGVideoShareDialogServiceDelegate> delegate;

/**
 初始化视频分享UI服务
 */
+ (void)registerService;

/**
 设置主题颜色。【地步按钮颜色】

 @param themeColor 颜色
 */
+ (void)configThemeColor:(UIColor *)themeColor;

@end

NS_ASSUME_NONNULL_END
