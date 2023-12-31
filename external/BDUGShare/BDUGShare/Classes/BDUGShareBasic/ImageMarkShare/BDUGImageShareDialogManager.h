//
//  BDUGImageShareDialogManager.h
//  BDUGShare
//
//  Created by zengzhihui on 2018/5/31.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, BDUGImageShareStatusCode) {
    BDUGImageShareStatusCodeSuccess = 0,//去分享
    BDUGImageShareStatusCodeUserCancel,//用户不去分享
    BDUGImageShareStatusCodeSaveImageToAlbumPermissionDenied,//保存图片权限被用户拒绝。
    BDUGImageShareStatusCodeSaveImageToAlbumFailed,//保存图片失败
    BDUGImageShareStatusCodeGetImageFailed,//获取隐写图片失败
    BDUGImageShareStatusCodePlatformOpenFailed,//打开第三方app失败
};

NS_ASSUME_NONNULL_BEGIN

@class BDUGImageShareContentModel;
@class BDUGImageShareAnalysisResultModel;

typedef void(^BDUGImageShareDialogBlock)(BDUGImageShareContentModel *contentModel);
typedef void(^BDUGImageShareAnalysisResultBlock)(BDUGImageShareAnalysisResultModel *resultModel);

typedef BOOL(^BDUGAdditionalImageShareDialogBlock)(BDUGImageShareContentModel *contentModel);
typedef BOOL(^BDUGAdditionalImageShareAnalysisResultBlock)(BDUGImageShareAnalysisResultModel *resultModel);

@interface BDUGImageShareDialogManager : NSObject

+ (instancetype)sharedManager;

//注册口令解析 -- 注册立即会调用解析方法，同时注册App进入前台通知
+ (void)imageShareRegisterDialogBlock:(BDUGImageShareDialogBlock)dialogBlock;
+ (void)imageShareRegisterAlbumAuthorizationDialogBlock:(BDUGImageShareDialogBlock)dialogBlock;

+ (void)imageAnalysisRegisterWithPermissionAlert:(BOOL)permissionAlert
                                     dialogBlock:(BDUGImageShareAnalysisResultBlock)dialogBlock;

+ (void)imageAnalysisRegisterWithPermissionAlert:(BOOL)permissionAlert
                                notificationName:(NSString * _Nullable)notificationName
                                     dialogBlock:(BDUGImageShareAnalysisResultBlock)dialogBlock;

+ (void)invokeImageShareDialogBlock:(BDUGImageShareContentModel *)contentModel;
+ (void)invokeImageShareAnalysisResultDialogBlock:(BDUGImageShareAnalysisResultModel *)resultModel;

+ (void)shareImage:(BDUGImageShareContentModel *)contentModel;
+ (void)cancelImageShare:(BDUGImageShareContentModel *)contentModel;

+ (void)triggerAlbumAuthorization;

#pragma mark - additional register

+ (void)additionalImageShareRegisterDialogBlock:(BDUGAdditionalImageShareDialogBlock)dialogBlock;
+ (void)additionalImageShareRegisterAlbumAuthorizationDialogBlock:(BDUGAdditionalImageShareDialogBlock)dialogBlock;
+ (void)additionalImageAnalysisRegisterDialogBlock:(BDUGAdditionalImageShareAnalysisResultBlock)dialogBlock;

@end

NS_ASSUME_NONNULL_END
