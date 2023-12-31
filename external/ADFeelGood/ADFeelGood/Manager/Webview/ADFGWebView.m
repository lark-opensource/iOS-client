//
//  ADFGWebView.m
//  ADFeelGood
//
//  Created by cuikeyi on 2021/3/10.
//

#import "ADFGWebView.h"
#import "ADFGWebModel.h"
#import "ADFeelGoodConfig+Private.h"
#import "ADFGWebViewBridgeEngine.h"
#import "ADFeelGoodBridgeNameDefines.h"
#import "ADFeelGoodURLConfig.h"
#import "ADFGUtils.h"

@interface ADFGWebView () <ADFGWKWebViewDelegate>

@property (nonatomic, strong) ADFGWKWebView *webView;
@property (nonatomic, strong) ADFGWebModel *webModel;
@property (nonatomic, strong) ADFeelGoodConfig *configModel;

@end

@implementation ADFGWebView

- (void)dealloc
{
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initViews];
        [self registerJSBridge];
    }
    return self;
}

- (void)initViews
{
    _webView = [[ADFGWKWebView alloc] initWithFrame:self.bounds configuration:[WKWebViewConfiguration new]];
    _webView.opaque = NO;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.scrollView.backgroundColor = [UIColor clearColor];
    _webView.slaveDelates = self;
    ADFGWebViewBridgeEngine *engine = [[ADFGWebViewBridgeEngine alloc] initWithBridgeRegister:ADFGBridgeRegister.new];
    [_webView adfg_installBridgeEngine:engine];
    [self addSubview:_webView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.webView.frame = self.bounds;
}

#pragma mark - Close
- (void)close
{
    [self removeFromSuperview];
}


#pragma mark - webview
- (BOOL)startRequsetWithWebModel:(ADFGWebModel *)webModel configModel:(ADFeelGoodConfig *)configModel error:(NSError ** _Nullable)error
{
    if (!configModel) {
        NSAssert(configModel, @"configModel 不能为空");
        *error = [ADFGUtils errorWithCode:ADFGErrorGlobalConfigNull msg:@"configModel 不能为空"];
        return NO;
    }
    // 解析taskid
    if (!webModel.taskID) {
        NSString *taskid = webModel.taskSettingDict[@"survey_task"][@"task_id"];
        if (taskid) {
            webModel.taskID = taskid;
        }
    }
    if (webModel.taskID.length == 0) {
        NSAssert(webModel.taskID.length > 0, @"taskid 不能为空");
        *error = [ADFGUtils errorWithCode:ADFGErrorTaskIDNull msg:@"taskid 不能为空"];
        return NO;
    }
    self.webModel = webModel;
    self.configModel = configModel;
    _webView.scrollView.scrollEnabled = webModel.scrollEnabled;
    NSString *urlString = [ADFeelGoodURLConfig baseURLWithChannel:configModel.channel];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    if ([webModel.taskID isEqualToString:@"preload"]) {// 预加载
        request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    }

    request.timeoutInterval = MAX(webModel.timeoutInterval, 5);
    [self.webView loadRequest:request];
    return YES;
}

- (void)registerJSBridge
{
    __weak typeof(self) weakSelf = self;
    [self.webView.adfg_engine registerBridge:^(ADFGBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(ADFGGetParams);
        maker.handler(^(NSDictionary * _Nullable params, ADFGBridgeCallback  _Nonnull callback, id<ADFGBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            if (callback) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                BOOL isExpired = strongSelf.webModel.isExpired;
                NSDictionary *taskSettingsDict = [strongSelf.webModel.taskSettingDict objectForKey:@"survey_task"];
                NSMutableDictionary *paramsDict = [strongSelf.configModel webviewParamsWithTaskID:strongSelf.webModel.taskID taskSetting:taskSettingsDict extraUserInfo:strongSelf.webModel.extraUserInfo];
                [paramsDict setObject:@(strongSelf.webModel.showLocalSubmitRecord) forKey:@"showLocalSubmitRecord"];
                [paramsDict adfg_setBool:isExpired forKey:@"isExpired"];
                callback(ADFGBridgeMsgSuccess, paramsDict, nil);
            }
        });
    }];
    
    [self.webView.adfg_engine registerBridge:^(ADFGBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(ADFGCloseContainer);
        maker.handler(^(NSDictionary * _Nullable params, ADFGBridgeCallback  _Nonnull callback, id<ADFGBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            BOOL submitSuccess = [[params objectForKey:@"success"] boolValue];
            if (strongSelf.closeCallback) {
                strongSelf.closeCallback(strongSelf, strongSelf.webModel, strongSelf.configModel, submitSuccess);
            }
            [strongSelf close];
        });
    }];
    
    [self.webView.adfg_engine registerBridge:^(ADFGBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(ADFGPostMessage);
        maker.handler(^(NSDictionary * _Nullable params, ADFGBridgeCallback  _Nonnull callback, id<ADFGBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.onMessageCallback) {
                strongSelf.onMessageCallback(strongSelf, strongSelf.webModel, strongSelf.configModel, params, callback);
            }
        });
    }];
    
    [self.webView.adfg_engine registerBridge:^(ADFGBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(ADFGContainerHeight);
        maker.handler(^(NSDictionary * _Nullable params, ADFGBridgeCallback  _Nonnull callback, id<ADFGBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf.containerHeightCallback) {
                CGFloat height = [[params objectForKey:@"height"] floatValue];
                strongSelf.containerHeightCallback(strongSelf, strongSelf.webModel, strongSelf.configModel, height);
            }
        });
    }];
}

- (void)fireEvent:(NSString *)eventName params:(NSDictionary *)params resultBlock:(void (^_Nullable)(NSString * _Nullable))resultBlock
{
    [self.webView.adfg_engine fireEvent:eventName params:params resultBlock:resultBlock];
}

#pragma mark - ADFGWKWebViewDelegate
- (void)webViewDidStartLoad:(ADFGWKWebView *)webView
{
    
}

- (void)webViewDidFinishLoad:(ADFGWKWebView *)webView
{
    if (self.finishCallback) {
        self.finishCallback(self, self.webModel, self.configModel);
    }
}

- (void)webView:(ADFGWKWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (self.failedCallback) {
        self.failedCallback(self, self.webModel, self.configModel, error);
    }
}

@end
