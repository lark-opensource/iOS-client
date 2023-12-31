//
//  BDUGTokenShareDialogManager.h
//  BDUGShare
//
//  Created by zengzhihui on 2018/5/31.
//

#import <Foundation/Foundation.h>
#import "BDUGTokenShareModel.h"
#import "BDUGTokenShare.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^BDUGTokenShareDialogBlock)(BDUGTokenShareInfo *tokenModel);
typedef void(^BDUGTokenShareAnalysisResultBlock)(BDUGTokenShareAnalysisResultModel * resultModel);

typedef BOOL(^BDUGAdditionalTokenShareDialogBlock)(BDUGTokenShareInfo * tokenModel);
typedef BOOL(^BDUGAdditionalTokenShareAnalysisResultBlock)(BDUGTokenShareAnalysisResultModel * resultModel);

typedef BOOL(^BDUGTokenShareShouldAnalysisBlock)(NSString * _Nullable tokenString);


@interface BDUGTokenShareDialogManager : NSObject

//注册口令解析 -- 注册立即会调用解析方法，同时注册App进入前台通知
+ (void)tokenShareRegisterDialogBlock:(BDUGTokenShareDialogBlock)dialogBlock;

+ (void)tokenAnalysisRegisterDialogBlock:(BDUGTokenShareAnalysisResultBlock)dialogBlock;

+ (void)tokenAnalysisRegisterDialogBlock:(BDUGTokenShareAnalysisResultBlock)dialogBlock
                        notificationName:(NSString * _Nullable)notificationName;

+ (void)tokenShouldAnalysisResisterBlock:(BDUGTokenShareShouldAnalysisBlock)shouldAnalysisBlock;

//todo：口令失效给个block，让业务选择是否弹窗？让产品定下。

+ (void)invokeTokenShareDialogBlock:(BDUGTokenShareInfo *)tokenModel;
+ (void)invokeTokenShareAnalysisResultDialogBlock:(BDUGTokenShareAnalysisResultModel *)resultModel;
+ (void)shareToken:(BDUGTokenShareInfo *)tokenModel;
+ (void)cancelTokenShare:(BDUGTokenShareInfo *)tokenModel;

+ (void)setLastToken:(NSString *)token;

/// 手动触发口令识别
+ (void)beginTokenAnalysis;

#pragma mark - additional register

+ (void)additionalTokenShareRegisterDialogBlock:(BDUGAdditionalTokenShareDialogBlock)dialogBlock;

+ (void)additionalTokenAnalysisRegisterDialogBlock:(BDUGAdditionalTokenShareAnalysisResultBlock)dialogBlock;

@end

NS_ASSUME_NONNULL_END
