//
//  ADFGWebView.h
//  ADFeelGood
//
//  Created by cuikeyi on 2021/3/10.
//

#import <UIKit/UIKit.h>
#import "ADFeelGoodWebHeader.h"

@class ADFGWebView, ADFGWebModel, ADFeelGoodConfig;

NS_ASSUME_NONNULL_BEGIN

typedef void(^LoadFinishCallback)(ADFGWebView *webview, ADFGWebModel *webModel, ADFeelGoodConfig *configModel);
typedef void(^LoadFailedCallback)(ADFGWebView *webview, ADFGWebModel *webModel, ADFeelGoodConfig *configModel, NSError *error);
typedef void(^CloseCallback)(ADFGWebView *webview, ADFGWebModel *webModel, ADFeelGoodConfig *configModel, BOOL submitSuccess);
typedef void(^ContainerHeightCallback)(ADFGWebView *webview, ADFGWebModel *webModel, ADFeelGoodConfig *configModel, CGFloat height);
typedef void(^OnMessageCallback)(ADFGWebView *webview, ADFGWebModel *webModel, ADFeelGoodConfig *configModel, NSDictionary * _Nullable params, ADFGBridgeCallback callback);

@interface ADFGWebView : UIView

/// 加载成功回调
@property (nonatomic, copy) LoadFinishCallback finishCallback;
/// 加载失败回调
@property (nonatomic, copy) LoadFailedCallback failedCallback;
/// webview关闭回调
@property (nonatomic, copy) CloseCallback closeCallback;
/// webview渲染完成后，前端回调高度
@property (nonatomic, copy) ContainerHeightCallback containerHeightCallback;
/// 透传前端 postMessage Bridge的回调
@property (nonatomic, copy) OnMessageCallback onMessageCallback;

/// 开始请求，加载
- (BOOL)startRequsetWithWebModel:(ADFGWebModel *)webModel configModel:(ADFeelGoodConfig *)configModel error:(NSError ** _Nullable)error;
/// 客户端通知前端
- (void)fireEvent:(NSString *)eventName params:(nullable NSDictionary *)params resultBlock:(void (^_Nullable)(NSString * _Nullable))resultBlock;

@end

NS_ASSUME_NONNULL_END
