//
//  BDUGVideoImageShareDialogManager.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/15.
//

#define BDUG_VIDEO_DIALOG_MGR [BDUGVideoImageShareDialogManager sharedManager]

#import <Foundation/Foundation.h>

@class BDUGVideoImageShareContentModel;
@class BDUGVideoImageShareInfo;

typedef NS_ENUM(NSInteger, BDUGVideoShareStatusCode) {
    BDUGVideoShareStatusCodeSuccess = 0,//去分享
    BDUGVideoShareStatusCodeInvalidContent,//分享数据不合规。
    BDUGVideoShareStatusCodeUserCancel,//用户不去分享 todo: 这个的回调。
    BDUGVideoShareStatusCodeVideoDownloadFailed,//视频下载失败
    BDUGVideoShareStatusCodeSaveVideoToAlbumPermissionDenied,//保存视频权限被用户拒绝。
    BDUGVideoShareStatusCodeSaveVideoToAlbumFailed,//保存视频失败
    BDUGVideoShareStatusCodePlatformOpenFailed,//打开第三方app失败
};

NS_ASSUME_NONNULL_BEGIN

typedef void(^BDUGVideoShareBlock)(void);
typedef void(^BDUGVideoSharePreviewDialogBlock)(BDUGVideoImageShareInfo *shareInfo, BDUGVideoShareBlock continueBlock);
typedef void(^BDUGVideoAlbumAuthorizationBlock)(BDUGVideoImageShareInfo *shareInfo, BDUGVideoShareBlock continueBlock);
typedef void(^BDUGVideoSaveSucceedDialogBlock)(BDUGVideoImageShareContentModel *contentModel, BDUGVideoShareBlock continueBlock);
typedef void(^BDUGVideoDownloadProgressBlock)(CGFloat progress);

@interface BDUGVideoImageShareDialogManager : NSObject

+ (instancetype)sharedManager;

//注册口令解析 -- 注册立即会调用解析方法，同时注册App进入前台通知

/**
 注册视频预览弹窗。

 @param dialogBlock 继续block
 */
+ (void)videoPreviewShareRegisterDialogBlock:(BDUGVideoSharePreviewDialogBlock)dialogBlock;

+ (void)videoPreviewShareRegisterDialogBlock:(BDUGVideoSharePreviewDialogBlock)dialogBlock
                               maxShowAmount:(NSInteger)showAmount;

/**
 注册相册权限弹窗

 @param authorizationBlock block中弹出相册权限。
 */
+ (void)albumAuthorizationRegisterDialogBlock:(BDUGVideoAlbumAuthorizationBlock)authorizationBlock;

/**
 注册保存成功弹窗

 @param dialogBlock 继续执行的block
 */
+ (void)videoSaveSucceedRegisterDialogBlock:(BDUGVideoSaveSucceedDialogBlock)dialogBlock;

/**
 注册loading progress弹窗

 @param progress 进度，0-1
 @param completion 下载完成弹窗
 */
+ (void)videoDownloadRegisterProgress:(BDUGVideoDownloadProgressBlock)progress
                           completion:(BDUGVideoShareBlock)completion;

#pragma mark - 业务方不用关心。

+ (void)invokeVideoPreviewDialogBlock:(BDUGVideoImageShareInfo *)shareInfo
                        continueBlock:(BDUGVideoShareBlock)continueBlock;

+ (void)invokeAlbumAuthorizationDialogBlock:(BDUGVideoImageShareInfo *)shareInfo
                              continueBlock:(BDUGVideoShareBlock)continueBlock;

+ (void)invokeVideoSaveSucceedDialogBlock:(BDUGVideoImageShareContentModel *)contentModel
                            continueBlock:(BDUGVideoShareBlock)continueBlock;

+ (void)invokeDownloadProgress:(CGFloat)progress;
+ (void)invokeDownloadCompletion;

@end

NS_ASSUME_NONNULL_END
