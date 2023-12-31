//
//  ADFeelGoodManager.m
//  FeelGoodDemo
//
//  Created by bytedance on 2020/8/26.
//  Copyright © 2020 huangyuanqing. All rights reserved.
//

#import "ADFeelGoodManager.h"
#import "ADFeelGoodViewController.h"
#import "ADFeelGoodParamKeysDefine.h"
#import "ADFeelGoodURLConfig.h"
#import "ADFeelGoodConfig.h"
#import "ADFeelGoodConfig+Private.h"
#import "ADFeelGoodOpenModel.h"
#import "ADFeelGoodOpenModel+Private.h"
#import "ADFeelGoodInfo.h"
#import "ADFeelGoodInfo+Private.h"
#import "UIViewController+ADFGPageMonitor.h"
#import "ADFGUtils.h"
#import "ADFGError.h"
#import "ADFGWebModel.h"

@interface ADFeelGoodManager()

@property (nonatomic, strong, nonnull) ADFeelGoodConfig *config;
@property (nonatomic, weak) ADFeelGoodViewController *currentVC;
@property (nonatomic, strong) UIWindow *globalWindow;

@end

@implementation ADFeelGoodManager

+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    static ADFeelGoodManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[ADFeelGoodManager alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
        if ([NSThread isMainThread]) {
            [UIViewController setupSwizzleMethod];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIViewController setupSwizzleMethod];
            });
        }
    }
    return self;
}

- (void)appWillResignActive:(NSNotification *)noti
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

/// 预加载feelgood web资源
- (void)preloadWithConfigModel:(ADFeelGoodConfig *)configModel
{
    ADFGWebView *webview = [self createWebViewWithLoadFinish:^(ADFGWebView * _Nonnull webview, ADFGWebModel * _Nonnull webModel, ADFeelGoodConfig * _Nonnull configModel) {
        [webview removeFromSuperview];
    } loadFailed:^(ADFGWebView * _Nonnull webview, ADFGWebModel * _Nonnull webModel, ADFeelGoodConfig * _Nonnull configModel, NSError * _Nonnull error) {
        [webview removeFromSuperview];
    } closeCallback:^(ADFGWebView * _Nonnull webview, ADFGWebModel * _Nonnull webModel, ADFeelGoodConfig * _Nonnull configModel, BOOL submitSuccess) {
        [webview removeFromSuperview];
    } containerHeightCallback:^(ADFGWebView * _Nonnull webview, ADFGWebModel * _Nonnull webModel, ADFeelGoodConfig * _Nonnull configModel, CGFloat height) {
        
    } onMessageCallback:^(ADFGWebView * _Nonnull webview, ADFGWebModel * _Nonnull webModel, ADFeelGoodConfig * _Nonnull configModel, NSDictionary * _Nullable params, ADFGBridgeCallback  _Nonnull callback) {
        
    }];
    webview.frame = CGRectZero;
    
    ADFGWebModel *webModel = [[ADFGWebModel alloc] init];
    webModel.taskID = @"preload";
    BOOL success = [webview startRequsetWithWebModel:webModel configModel:configModel error:nil];
    if (success) {
        [[UIApplication sharedApplication].keyWindow addSubview:webview];
    }
}

#pragma mark - triggerEvent && open
/// 上报事件
/// @param eventID 用户行为事件标识
/// @param extraUserInfo 自定义用户标识，请求时添加到user字典中
/// @param completion 请求成功回调
- (void)triggerEventWithEvent:(NSString *)eventID
                extraUserInfo:(NSDictionary *)extraUserInfo
             reportCompletion:(nullable void (^)(BOOL success, NSDictionary *dataDict, NSError *error, ADFeelGoodInfo *infoModel))completion
{
    NSAssert(eventID.length > 0, @"eventID 不能为空");
    NSAssert(self.config, @"config 不能为空");
    if (eventID.length == 0) {
        if (completion) {
            NSError *error = [ADFGUtils errorWithCode:ADFGErrorEventNull msg:@"eventid为空"];
            completion(NO, nil, error, nil);
        }
        return;
    }
    if (!self.config) {
        if (completion) {
            NSError *error = [ADFGUtils errorWithCode:ADFGErrorGlobalConfigNull msg:@"全局配置模型为空"];
            completion(NO, nil, error, nil);
        }
        return;
    }
    [self checkQuestionnaireWithEventID:eventID
                            extraParams:extraUserInfo
                             completion:^(BOOL success, NSDictionary * _Nonnull data, NSError * _Nonnull error) {
        
        ADFeelGoodInfo *infoModel = nil;
        if (success) {
            NSDictionary *dataDict = [data adfg_dictionaryForKey:@"data" defaultValue:nil];
            NSArray *list = [dataDict adfg_arrayForKey:@"task_list" defaultValue:nil];
            NSArray *delayList = [dataDict adfg_arrayForKey:@"delay_task_list" defaultValue:nil];
            NSDictionary *taskSettings = [dataDict adfg_dictionaryForKey:@"task_settings" defaultValue:nil];
            infoModel = [[ADFeelGoodInfo alloc] init];
            infoModel.triggerResult = data;
            // 正常问卷
            if ([list count] > 0) {
                infoModel.taskID = [list adfg_stringAtIndex:0 defaultValue:nil];
            }
            // 延迟问卷
            else if ([delayList count] > 0) {
                infoModel.taskID = [delayList adfg_stringAtIndex:0 defaultValue:nil];
            }
            // 获取配置
            NSDictionary *taskSetting = [taskSettings adfg_dictionaryForKey:infoModel.taskID defaultValue:nil];
            NSDictionary *surveyTask = [taskSetting adfg_dictionaryForKey:@"survey_task" defaultValue:nil];
            NSDictionary *commonConfigDict = [surveyTask adfg_dictionaryForKey:@"common_config" defaultValue:nil];
            NSDictionary *appearanceDict = [commonConfigDict adfg_dictionaryForKey:@"appearance" defaultValue:nil];
            NSDictionary *mobileDict = [appearanceDict adfg_dictionaryForKey:@"mobile" defaultValue:nil];
            BOOL globalDialog = [mobileDict adfg_boolForKey:@"native_global_dialog" defaultValue:NO];
            infoModel.globalDialog = globalDialog;
        }
        if (completion) {
            completion(success, data, error, infoModel);
        }
    }];
}

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
                 didClose:(nullable void (^)(BOOL submitSuccess, ADFeelGoodInfo *infoModel))didCloseBlock
{
    [self openWithOpenModel:openModel infoModel:infoModel enableOpen:^BOOL(ADFeelGoodInfo * _Nonnull infoModel) {
        return YES;
    } willOpen:willOpenBlock didOpen:didOpenBlock didClose:didCloseBlock];
}

- (void)openWithTaskID:(NSString *)taskID
                 openModel:(ADFeelGoodOpenModel *)openModel
            enableOpen:(nullable BOOL (^)(ADFeelGoodInfo *infoModel))enableOpen
              willOpen:(nullable BOOL (^)(ADFeelGoodInfo *infoModel))willOpenBlock
               didOpen:(nullable void (^)(BOOL success, ADFeelGoodInfo *infoModel, NSError *error))didOpenBlock
              didClose:(nullable void (^)(BOOL submitSuccess, ADFeelGoodInfo *infoModel))didCloseBlock
{
    
    ADFeelGoodInfo * infoModel = [ADFeelGoodInfo createInfoModel:taskID triggerResult:nil globalDialog:NO];
    infoModel.enableOpenBlock = enableOpen;
    infoModel.willOpenBlock = willOpenBlock;
    infoModel.didOpenBlock = didOpenBlock;
    infoModel.didCloseBlock = didCloseBlock;
    openModel.infoModel = infoModel;
    
    [self _openWithOpenModel:openModel];
}

/// 打开问卷
/// @param openModel 问卷配置模型
/// @param infoModel trigger信息，将triggerEventWithEvent中返回的infoModel传递过来即可
/// @param willOpenBlock 页面即将打开回调，可返回bool值控制是否弹出feelgood页面
/// @param didOpen feelgood页面显示完毕回调
/// @param didClose feelgood页面关闭回调
- (void)openWithOpenModel:(ADFeelGoodOpenModel *)openModel
                infoModel:(ADFeelGoodInfo *)infoModel
               enableOpen:(nullable BOOL (^)(ADFeelGoodInfo *infoModel))enableOpen
                 willOpen:(nullable BOOL (^)(ADFeelGoodInfo *infoModel))willOpenBlock
                  didOpen:(nullable void (^)(BOOL success, ADFeelGoodInfo *infoModel, NSError *error))didOpenBlock
                 didClose:(nullable void (^)(BOOL submitSuccess, ADFeelGoodInfo *infoModel))didCloseBlock
{
    if (infoModel.triggerResult.count == 0) {
        if (didOpenBlock) {
            NSError *error = [ADFGUtils errorWithCode:ADFGErrorTriggerResultParams msg:@"triggerResult为空，打开页面失败"];
            didOpenBlock(NO, infoModel, error);
        }
        return;
    }
    NSAssert(self.config, @"config 不能为空");
    if (!self.config) {
        if (didOpenBlock) {
            NSError *error = [ADFGUtils errorWithCode:ADFGErrorGlobalConfigNull msg:@"全局配置模型为空"];
            didOpenBlock(NO, infoModel, error);
        }
        return;
    }
    infoModel.enableOpenBlock = enableOpen;
    infoModel.willOpenBlock = willOpenBlock;
    infoModel.didOpenBlock = didOpenBlock;
    infoModel.didCloseBlock = didCloseBlock;
    openModel.infoModel = infoModel;
    
    NSDictionary *dataDict = [infoModel.triggerResult adfg_dictionaryForKey:@"data" defaultValue:nil];
    NSArray *list = [dataDict adfg_arrayForKey:@"task_list" defaultValue:nil];
    NSArray *delayList = [dataDict adfg_arrayForKey:@"delay_task_list" defaultValue:nil];
    NSDictionary *taskSettings = [dataDict adfg_dictionaryForKey:@"task_settings" defaultValue:nil];
    // 正常问卷
    if ([list count] > 0) {
        NSDictionary *taskSetting = [taskSettings adfg_dictionaryForKey:infoModel.taskID defaultValue:nil];
        infoModel.taskSetting = [taskSetting adfg_dictionaryForKey:@"survey_task" defaultValue:nil];
        [self _openWithOpenModel:openModel];
    }
    // 延迟问卷
    else if ([delayList count] > 0) {
        // 延时任务禁止配置成全局弹框
        if (infoModel.isGlobalDialog) {
            if (didOpenBlock) {
                NSError *error = [ADFGUtils errorWithCode:ADFGErrorGlobalDialogDalay msg:@"延时任务禁止配置成全局弹框"];
                didOpenBlock(NO, infoModel, error);
            }
            return;
        }
        NSDictionary *taskSetting = [taskSettings adfg_dictionaryForKey:infoModel.taskID defaultValue:nil];
        infoModel.taskSetting = [taskSetting adfg_dictionaryForKey:@"survey_task" defaultValue:nil];
        // 对需要等待用户停留一定时间再触发的任务, 不做超时限制;
        infoModel.requestTimeoutAt = nil;
        // 页面没有释放 && 页面在window上时，开始计时
        UIViewController *targetController = openModel.parentVC;
        if (targetController && targetController.view.window) {
            NSTimeInterval interval = [taskSetting adfg_doubleForKey:@"delay_duration" defaultValue:0];
            [self performSelector:@selector(_openWithOpenModel:) withObject:openModel afterDelay:interval];
            [targetController setAdfgViewDidDisappearBlock:^(BOOL animation) {
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_openWithOpenModel:) object:openModel];
            }];
        }
    } else {
        if (didOpenBlock) {
            NSError *error = [ADFGUtils errorWithCode:ADFGErrorGlobalConfigNull msg:@"问卷列表返回为空"];
            didOpenBlock(NO, infoModel, error);
        }
        return;
    }
}

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
                            didClose:(nullable void (^)(BOOL submitSuccess, ADFeelGoodInfo *infoModel))didClose
{
    [self triggerEventAndOpenWithEvent:eventID openModel:openModel reportCompletion:completion enableOpen:^BOOL(ADFeelGoodInfo * _Nonnull infoModel) {
        return YES;
    } willOpen:willOpenBlock didOpen:didOpen didClose:didClose];
}

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
                            didClose:(nullable void (^)(BOOL submitSuccess, ADFeelGoodInfo *infoModel))didClose
{
    NSDate *requestDate = nil;
    if (openModel.timeoutInterval > 0) {
        requestDate = [NSDate dateWithTimeIntervalSinceNow:openModel.timeoutInterval];
    }
    [self triggerEventWithEvent:eventID extraUserInfo:openModel.extraUserInfo reportCompletion:^(BOOL success, NSDictionary * _Nonnull dataDict, NSError * _Nonnull error, ADFeelGoodInfo * _Nonnull infoModel) {
        infoModel.requestTimeoutAt = requestDate;
        if (completion) {
            completion(success, dataDict, error, infoModel);
        }
        if (success) {
            [self openWithOpenModel:openModel infoModel:infoModel enableOpen:enableOpen willOpen:willOpenBlock didOpen:didOpen didClose:didClose];
        }
    }];
}

- (ADFGWebView *)createWebViewWithLoadFinish:(LoadFinishCallback)finishCallback
                                  loadFailed:(LoadFailedCallback)failedCallback
                               closeCallback:(CloseCallback)closeCallback
                     containerHeightCallback:(ContainerHeightCallback)containerHeightCallback
                           onMessageCallback:(OnMessageCallback)onMessageCallback
{
    ADFGWebView *webview = [[ADFGWebView alloc] init];
    webview.finishCallback = finishCallback;
    webview.failedCallback = failedCallback;
    webview.closeCallback = closeCallback;
    webview.containerHeightCallback = containerHeightCallback;
    webview.onMessageCallback = onMessageCallback;
    return webview;
}

/// 获取调研问卷的地址链接
/// @param channel cn/va 中国区/非中国区
- (NSString *)feelgoodWebURLStringWithChannel:(nullable NSString *)channel
{
    NSString *urlStr = [ADFeelGoodURLConfig baseURLWithChannel:channel];
    return urlStr;
}

#pragma mark - 待废弃接口
/// 上报用户行为，并直接弹出可以展示的问卷
/// @param eventID 用户行为事件标识
/// @param openModel 问卷配置模型
/// @param willOpenBlock 页面即将打开回调，可返回bool值控制是否弹出feelgood页面
/// @param didOpen feelgood页面显示完毕回调
/// @param didClose feelgood页面关闭回调
/// @param reportCompletion report请求回调
- (void)triggerEventAndOpenWithEvent:(NSString *)eventID openModel:(ADFeelGoodOpenModel *)openModel willOpen:(nullable BOOL (^)(void))willOpenBlock didOpen:(nullable void (^)(void))didOpen didClose:(nullable void (^)(BOOL submitSuccess))didClose reportCompletion:(nullable void (^)(BOOL success, NSDictionary *dataDict, NSError *error))completion openError:(nullable void (^)(NSError *error))openError
{
    [self triggerEventAndOpenWithEvent:eventID openModel:openModel reportCompletion:^(BOOL success, NSDictionary * _Nonnull dataDict, NSError * _Nonnull error, ADFeelGoodInfo * _Nonnull infoModel) {
        if (completion) {
            completion(success, dataDict, error);
        }
    } willOpen:^BOOL(ADFeelGoodInfo * _Nonnull infoModel) {
        BOOL enableOpen = YES;
        if (willOpenBlock) {
            enableOpen = willOpenBlock();
        }
        return enableOpen;
    } didOpen:^(BOOL success, ADFeelGoodInfo * _Nonnull infoModel, NSError * _Nonnull error) {
        if (didOpen) {
            didOpen();
        }
    } didClose:^(BOOL submitSuccess, ADFeelGoodInfo * _Nonnull infoModel) {
        if (didClose) {
            didClose(submitSuccess);
        }
    }];
}

/// 上报用户行为，并直接弹出可以展示的问卷
/// @param eventID 用户行为事件标识
/// @param openModel 问卷配置模型
/// @param willOpenBlock 页面即将打开回调，可返回bool值控制是否弹出feelgood页面
/// @param didOpen feelgood页面显示完毕回调
/// @param didClose feelgood页面关闭回调
- (void)triggerEventAndOpenWithEvent:(NSString *)eventID openModel:(ADFeelGoodOpenModel *)openModel willOpen:(nullable BOOL (^)(void))willOpenBlock didOpen:(nullable void (^)(void))didOpen didClose:(nullable void (^)(BOOL submitSuccess))didClose
{
    [self triggerEventAndOpenWithEvent:eventID openModel:openModel willOpen:willOpenBlock didOpen:didOpen didClose:didClose reportCompletion:nil openError:nil];
}

#pragma mark - 打开问卷
- (void)_openWithOpenModel:(ADFeelGoodOpenModel *)model
{
    ADFeelGoodInfo *infoModel = model.infoModel;
    BOOL enableOpen = YES;
    if (infoModel.enableOpenBlock) {
        enableOpen = infoModel.enableOpenBlock(infoModel);
    }
    if (!enableOpen) {
        return;
    }
    if (!self.config) {
        NSAssert(self.config, @"config 不能为空");
        if (infoModel.didOpenBlock) {
            NSError *error = [ADFGUtils errorWithCode:ADFGErrorGlobalConfigNull msg:@"全局配置模型为空"];
            infoModel.didOpenBlock(NO, infoModel, error);
        }
        return;
    }
    NSString *urlStr = [ADFeelGoodURLConfig baseURLWithChannel:self.config.channel];
    if (urlStr.length == 0) {
        NSAssert(urlStr.length, @"infoModel.url 不能为空,请检查trigger接口返回是否正常");
        if (infoModel.didOpenBlock) {
            NSError *error = [ADFGUtils errorWithCode:ADFGErrorOpenURLNull msg:@"打开页面URL为空，打开失败"];
            infoModel.didOpenBlock(NO, infoModel, error);
        }
        return;
    }
    // 配置参数
    NSMutableDictionary *webviewParams = [self.config webviewParamsWithTaskID:infoModel.taskID taskSetting:infoModel.taskSetting extraUserInfo:model.extraUserInfo];
    infoModel.webviewParams = webviewParams;
    infoModel.url = [NSURL URLWithString:urlStr];
    
    void (^openBlock) (void) = ^ {
        // 页面级弹框
        if (!infoModel.isGlobalDialog) {
            // feelgood页面被释放了，过滤掉
            if (!model.parentVC) {
                return;
            }
            // feelgood页面不在window上，过滤掉
            if (!model.parentVC.view.window) {
                return;
            }
        }
        ADFeelGoodViewController *vc = [[ADFeelGoodViewController alloc] initWithOpenModel:model];
        // 屏幕中已有任务，无法推出新页面
        if (!vc) {
            return;
        }
        _currentVC = vc;
        // 类型判断
        if (infoModel.isGlobalDialog || model.openType == ADFGOpenTypeWindow) {// 全局弹框
            [self createGlobalWindowIfNeed];
            #ifdef __IPHONE_13_0
            if (@available(iOS 13.0, *)) {
               _globalWindow.windowScene = model.windowScene;
            }
            #endif
            _globalWindow.rootViewController = vc;
            [_globalWindow makeKeyAndVisible];
            [vc prepareiPadLayoutModeParams];
            vc.closeBlock = ^{
                [self disposeGlobalWindow];
            };
        } else {// 页面级弹框
            [model.parentVC addChildViewController:vc];
            [model.parentVC.view addSubview:vc.view];
        }
    };
    
    if ([NSThread currentThread].isMainThread) {
        openBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            openBlock();
        });
    }
}

#pragma mark - 关闭问卷
- (void)closeTask
{
    if (_currentVC) {
        [_currentVC close];
        _currentVC = nil;
        [self disposeGlobalWindow];
    }
}

- (void)createGlobalWindowIfNeed
{
    if (!_globalWindow) {
        _globalWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _globalWindow.windowLevel = UIWindowLevelAlert - 1;
    }
}

- (void)disposeGlobalWindow
{
    if (_globalWindow) {
        [_globalWindow resignKeyWindow];
        _globalWindow = nil;
    }
}

#pragma mark 请求问卷信息
//请求问卷最终接口
- (void)checkQuestionnaireWithEventID:(NSString *)eventID
                          extraParams:(nullable NSDictionary *)extraParams
                           completion:(void(^)(BOOL success, NSDictionary *data, NSError *error))completion
{
    //获取参数
    NSMutableDictionary *params = [self.config checkQuestionParamsWithEventID:eventID extraUserInfo:extraParams];
    //检查参数字典能否转化为data
    NSAssert([NSJSONSerialization isValidJSONObject:params], @"参数json data化失败");
    
    NSString *checkURLStr = [ADFeelGoodURLConfig checkURLWithChannel:self.config.channel];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:checkURLStr]];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[self.config headerOrigin] forHTTPHeaderField:@"Origin"];
    [request setValue:[self.config headerOrigin]  forHTTPHeaderField:@"Referer"];
    // TODO: 替换为常量
    [request setValue:@"v2" forHTTPHeaderField:@"x-feelgood-api-version"];
    
    NSError *error = nil;
    NSData *jsonData = nil;
    if (params.count > 0 && [NSJSONSerialization isValidJSONObject:params]) {
        jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&error];
    }
    if (jsonData && !error) {
        [request setHTTPBody:jsonData];
    }
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        BOOL success = (error == nil);
        NSDictionary *dict = nil;
        if (data) {
            dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingFragmentsAllowed error:NULL];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(success,dict,error);
            }
        });
    }];
    [task resume];
}
 
@end
