//
//  ADFeelGoodInfo+Private.h
//  ADFeelGood
//
//  Created by cuikeyi on 2021/2/2.
//

#import "ADFeelGoodInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface ADFeelGoodInfo (Private)

#pragma mark - public
/// Event taskid
@property (nonatomic, copy, nullable) NSString *taskID;
/// triggerEvent返回的数据
@property (nonatomic, strong, nullable) NSDictionary *triggerResult;
/// 是否为全局弹框
@property (nonatomic, assign, getter=isGlobalDialog) BOOL globalDialog;

#pragma mark - private
/// 不需要暴露，传递给Bridge
@property (nonatomic, strong) NSDictionary *taskSetting;
/// webview页面链接  内部
@property (nonatomic, strong) NSURL *url;
/// 透传给webview的数据
@property (nonatomic, strong) NSDictionary *webviewParams;
/// 内部使用，标记过期时间用的
@property (nonatomic, strong, nullable) NSDate *requestTimeoutAt;

// 回调
@property (nonatomic, copy) BOOL(^enableOpenBlock)(ADFeelGoodInfo *infoModel);
@property (nonatomic, copy) BOOL(^willOpenBlock)(ADFeelGoodInfo *infoModel);
@property (nonatomic, copy) void(^didOpenBlock)(BOOL success, ADFeelGoodInfo *infoModel, NSError *error);
@property (nonatomic, copy) void(^didCloseBlock)(BOOL submitSuccess, ADFeelGoodInfo *infoModel);

@end

NS_ASSUME_NONNULL_END
