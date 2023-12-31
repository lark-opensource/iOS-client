//
//  ADFeelGoodManager.h
//  FeelGoodDemo
//
//  Created by bytedance on 2020/8/26.
//  Copyright © 2020 huangyuanqing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ADFGWebView.h"

@class ADFeelGoodConfig, ADFeelGoodOpenModel, ADFeelGoodInfo;

NS_ASSUME_NONNULL_BEGIN

@interface ADFeelGoodManager : NSObject

+ (instancetype)sharedInstance;

/// 预加载feelgood web资源
- (void)preloadWithConfigModel:(ADFeelGoodConfig *)configModel;

/// 设置更新配置
/// @param config 配置model
- (void)setConfig:(nonnull ADFeelGoodConfig *)config;

#pragma mark - triggerEvent && open
/// 上报事件
/// @param eventID 用户行为事件标识
/// @param extraUserInfo 自定义用户标识，请求时添加到user字典中
/// @param completion 请求成功回调
- (void)triggerEventWithEvent:(NSString *)eventID
                extraUserInfo:(NSDictionary *)extraUserInfo
             reportCompletion:(nullable void (^)(BOOL success, NSDictionary *dataDict, NSError *error, ADFeelGoodInfo *infoModel))completion;


- (void)openWithTaskID:(NSString *)taskID
                 openModel:(ADFeelGoodOpenModel *)openModel
            enableOpen:(nullable BOOL (^)(ADFeelGoodInfo *infoModel))enableOpen
              willOpen:(nullable BOOL (^)(ADFeelGoodInfo *infoModel))willOpenBlock
               didOpen:(nullable void (^)(BOOL success, ADFeelGoodInfo *infoModel, NSError *error))didOpenBlock
              didClose:(nullable void (^)(BOOL submitSuccess, ADFeelGoodInfo *infoModel))didCloseBlock;

/// 打开问卷
/// @param openModel 问卷配置模型
/// @param infoModel trigger信息，将triggerEventWithEvent中返回的infoModel传递过来即可
/// @param willOpenBlock 页面即将打开回调，可返回bool值控制是否弹出feelgood页面
/// @param didOpen feelgood页面显示完毕回调
/// @param didClose feelgood页面关闭回调
- (void)openWithOpenModel:(ADFeelGoodOpenModel *)openModel
                infoModel:(ADFeelGoodInfo *)infoModel
                 willOpen:(nullable BOOL (^)(ADFeelGoodInfo *infoModel))willOpenBlock
                  didOpen:(nullable void (^)(BOOL success, ADFeelGoodInfo *infoModel, NSError *error))didOpenBlock
                 didClose:(nullable void (^)(BOOL submitSuccess, ADFeelGoodInfo *infoModel))didCloseBlock;

/// 打开问卷
/// @param openModel 问卷配置模型
/// @param infoModel trigger信息，将triggerEventWithEvent中返回的infoModel传递过来即可
/// @param enableOpen 是否允许打开webview控制器
/// @param willOpenBlock 页面即将打开回调，可返回bool值控制是否弹出feelgood页面
/// @param didOpen feelgood页面显示完毕回调
/// @param didClose feelgood页面关闭回调
- (void)openWithOpenModel:(ADFeelGoodOpenModel *)openModel
                infoModel:(ADFeelGoodInfo *)infoModel
               enableOpen:(nullable BOOL (^)(ADFeelGoodInfo *infoModel))enableOpen
                 willOpen:(nullable BOOL (^)(ADFeelGoodInfo *infoModel))willOpenBlock
                  didOpen:(nullable void (^)(BOOL success, ADFeelGoodInfo *infoModel, NSError *error))didOpenBlock
                 didClose:(nullable void (^)(BOOL submitSuccess, ADFeelGoodInfo *infoModel))didCloseBlock;

/// 上报用户行为，并直接弹出可以展示的问卷
/// @param eventID 用户行为事件标识
/// @param openModel 打开问卷配置模型
/// @param completion triggerEvent接口上报完成回调
/// @param willOpenBlock 页面即将打开回调，可返回bool值控制是否弹出feelgood页面
/// @param didOpen feelgood页面显示完毕回调
/// @param didClose feelgood页面关闭回调
- (void)triggerEventAndOpenWithEvent:(NSString *)eventID
                           openModel:(ADFeelGoodOpenModel *)openModel
                    reportCompletion:(nullable void (^)(BOOL success, NSDictionary *dataDict, NSError *error, ADFeelGoodInfo *infoModel))completion
                            willOpen:(nullable BOOL (^)(ADFeelGoodInfo *infoModel))willOpenBlock
                             didOpen:(nullable void (^)(BOOL success, ADFeelGoodInfo *infoModel, NSError *error))didOpen
                            didClose:(nullable void (^)(BOOL submitSuccess, ADFeelGoodInfo *infoModel))didClose;

/// 上报用户行为，并直接弹出可以展示的问卷
/// @param eventID 用户行为事件标识
/// @param openModel 打开问卷配置模型
/// @param completion triggerEvent接口上报完成回调
/// @param enableOpen 是否允许打开webview控制器
/// @param willOpenBlock webview页面即将打开回调，可返回bool值控制是否弹出feelgood页面
/// @param didOpen feelgood页面显示完毕回调
/// @param didClose feelgood页面关闭回调
- (void)triggerEventAndOpenWithEvent:(NSString *)eventID
                           openModel:(ADFeelGoodOpenModel *)openModel
                    reportCompletion:(nullable void (^)(BOOL success, NSDictionary *dataDict, NSError *error, ADFeelGoodInfo *infoModel))completion
                          enableOpen:(nullable BOOL (^)(ADFeelGoodInfo *infoModel))enableOpen
                            willOpen:(nullable BOOL (^)(ADFeelGoodInfo *infoModel))willOpenBlock
                             didOpen:(nullable void (^)(BOOL success, ADFeelGoodInfo *infoModel, NSError *error))didOpen
                            didClose:(nullable void (^)(BOOL submitSuccess, ADFeelGoodInfo *infoModel))didClose;

// 关闭问卷
- (void)closeTask;

#pragma mark - 抖音端
/// 获取webview页面，由业务自行负责页面的展示、隐藏逻辑。
/// @param finishCallback 加载完成回调
/// @param failedCallback 加载失败回调
/// @param closeCallback 页面关闭回调
/// @param containerHeightCallback web页面高度回调，FeelGood页面加载完毕返回
/// @param onMessageCallback Web与Native通讯回调，透传前端 postMessage Bridge的通知
- (ADFGWebView *)createWebViewWithLoadFinish:(LoadFinishCallback)finishCallback
                                  loadFailed:(LoadFailedCallback)failedCallback
                               closeCallback:(CloseCallback)closeCallback
                     containerHeightCallback:(ContainerHeightCallback)containerHeightCallback
                           onMessageCallback:(OnMessageCallback)onMessageCallback;

/// 获取调研问卷的地址链接，channel为空时，默认为中国区
/// @param channel cn/va 中国区/非中国区
- (NSString *)feelgoodWebURLStringWithChannel:(nullable NSString *)channel;

#pragma mark - 废弃待删除
/// 上报用户行为，并直接弹出可以展示的问卷
/// @param eventID 用户行为事件标识
/// @param openModel 问卷配置模型
/// @param willOpenBlock 页面即将打开回调，可返回bool值控制是否弹出feelgood页面
/// @param didOpen feelgood页面显示完毕回调
/// @param didClose feelgood页面关闭回调
- (void)triggerEventAndOpenWithEvent:(NSString *)eventID openModel:(ADFeelGoodOpenModel *)openModel willOpen:(nullable BOOL (^)(void))willOpenBlock didOpen:(nullable void (^)(void))didOpen didClose:(nullable void (^)(BOOL submitSuccess))didClose;
//DEPRECATED_MSG_ATTRIBUTE("use triggerEventAndOpenWithEvent:openModel:willOpen:didOpen:openError:didClose: instead");

/// 上报用户行为，并直接弹出可以展示的问卷
/// @param eventID 用户行为事件标识
/// @param openModel 问卷配置模型
/// @param willOpenBlock 页面即将打开回调，可返回bool值控制是否弹出feelgood页面
/// @param didOpen feelgood页面显示完毕回调
/// @param didClose feelgood页面关闭回调
/// @param reportCompletion report请求回调
/// @param openError webview打开报错回调
- (void)triggerEventAndOpenWithEvent:(NSString *)eventID openModel:(ADFeelGoodOpenModel *)openModel willOpen:(nullable BOOL (^)(void))willOpenBlock didOpen:(nullable void (^)(void))didOpen didClose:(nullable void (^)(BOOL submitSuccess))didClose reportCompletion:(nullable void (^)(BOOL success, NSDictionary *dataDict, NSError *error))completion openError:(nullable void (^)(NSError *error))openError;
//DEPRECATED_MSG_ATTRIBUTE("use openUrlService:handleQuery: instead");



@end

NS_ASSUME_NONNULL_END
