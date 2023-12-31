//
//  CJPayBaseLynxView.h
//  Aweme_xiaohong
//
//  Created by wangxiaohong on 2023/2/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayLynxViewDelegate <NSObject>

@optional
- (void)viewDidConstructJSRuntime;
- (void)viewWillCreated;
- (void)viewDidCreated;
- (void)viewDidChangeIntrinsicContentSize:(CGSize)size;
- (void)viewDidStartLoading;
- (void)viewDidFirstScreen;
- (void)viewDidFinishLoadWithError:(NSError *_Nullable)error; //未引入LynxCard子模块的回调报错
- (void)viewDidFinishLoadWithURL:(NSString *_Nullable)url;
- (void)viewDidUpdate;
// 用于lynx页面刷新立即回调，承接BDLynxView的同名协议并继续往外抛
- (void)viewDidPageUpdate;
//on exception or error
- (void)viewDidRecieveError:(NSError *_Nullable)error;
//did load fail(Lynx fallback & webview didFailProvisionalNavigation)
- (void)viewDidLoadFailedWithUrl:(NSString *_Nullable)url error:(NSError *_Nullable)error;

// 接收Lynx事件
- (void)lynxView:(UIView *)lynxView receiveEvent:(NSString *)event withData:(NSDictionary *)data;

@end

@interface CJPayBaseLynxView : UIView

- (instancetype)initWithFrame:(CGRect)frame
                       scheme:(NSString *)scheme
                  initDataStr:(nonnull NSString *)paramsStr;

@property (nonatomic, weak) id<CJPayLynxViewDelegate> delegate;

@property (nonatomic, copy, readonly) NSDictionary *data;

- (void)reload;

//子类可以直接使用，用于给Lynx发送消息
- (void)publishEvent:(NSString *)event data:(NSDictionary *)data;

@end

NS_ASSUME_NONNULL_END
