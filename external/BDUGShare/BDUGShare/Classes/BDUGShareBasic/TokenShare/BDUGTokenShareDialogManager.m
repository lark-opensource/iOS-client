//
//  BDUGTokenShareDialogManager.m
//  BDUGShare
//
//  Created by zengzhihui on 2018/5/31.
//

#import "BDUGTokenShareDialogManager.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "BDUGTokenShareModel.h"
#import "BDUGTokenShare.h"
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTDefaultHTTPRequestSerializer.h>
#import <TTNetworkManager/TTHTTPResponseSerializerBase.h>
#import "BDUGShareEvent.h"
#import "BDUGShareSettingsUtil.h"
#import "BDUGShareBaseUtil.h"
#import "BDUGShareSequenceManager.h"

static NSString * const kBDUGTokenSharePasteboardLastState = @"kBDUGTokenSharePasteboardLastState";// 上一次是否卡死
//static NSString * const kBDUGTokenSharePasteboardLastAsync = @"kBDUGTokenSharePasteboardLastAsync";// 上一次是否异步

static NSString * const kBDUGTokenShareLastShareTokenKey = @"kBDUGTokenShareLastShareTokenKey";


@interface BDUGTokenShareDialogManager ()
{
    NSString *_lastShareToken;
}

@property (nonatomic, copy) BDUGTokenShareDialogBlock tokenShareDialogBlock;
@property (nonatomic, copy) BDUGTokenShareAnalysisResultBlock tokenAnalysisDialogBlock;

@property (nonatomic, strong) NSMutableArray <BDUGAdditionalTokenShareDialogBlock> *additionalShareDialogs;
@property (nonatomic, strong) NSMutableArray <BDUGAdditionalTokenShareAnalysisResultBlock> *additionalAnalysisDialogs;

@property (nonatomic, copy) BDUGTokenShareShouldAnalysisBlock tokenShouldAnalysisBlock;

@property (nonatomic, copy) NSString *lastShareToken;

@end

@implementation BDUGTokenShareDialogManager

+ (void)tokenShareRegisterDialogBlock:(BDUGTokenShareDialogBlock)dialogBlock {
    [BDUGTokenShareDialogManager sharedManager].tokenShareDialogBlock = dialogBlock;
}

+ (void)additionalTokenShareRegisterDialogBlock:(BDUGAdditionalTokenShareDialogBlock)dialogBlock {
    [[BDUGTokenShareDialogManager sharedManager].additionalShareDialogs addObject:dialogBlock];
}

+ (void)tokenAnalysisRegisterDialogBlock:(BDUGTokenShareAnalysisResultBlock)dialogBlock
{
    [self tokenAnalysisRegisterDialogBlock:dialogBlock notificationName:nil];
}

+ (void)additionalTokenAnalysisRegisterDialogBlock:(BDUGAdditionalTokenShareAnalysisResultBlock)dialogBlock {
    [[BDUGTokenShareDialogManager sharedManager].additionalAnalysisDialogs addObject:dialogBlock];
    [[BDUGTokenShareDialogManager sharedManager] registerTokenAnalysisWithNotificationName:nil];
}

+ (void)tokenAnalysisRegisterDialogBlock:(BDUGTokenShareAnalysisResultBlock)dialogBlock
                        notificationName:(NSString *)notificationName
{
    [BDUGTokenShareDialogManager sharedManager].tokenAnalysisDialogBlock = dialogBlock;
    [[BDUGTokenShareDialogManager sharedManager] registerTokenAnalysisWithNotificationName:notificationName];
}

+ (void)tokenShouldAnalysisResisterBlock:(BDUGTokenShareShouldAnalysisBlock)shouldAnalysisBlock
{
    [BDUGTokenShareDialogManager sharedManager].tokenShouldAnalysisBlock = shouldAnalysisBlock;
}

+ (void)invokeTokenShareDialogBlock:(BDUGTokenShareInfo *)tokenModel {
    [[BDUGTokenShareDialogManager sharedManager] invokeTokenShareDialogBlock:tokenModel];
}

+ (void)invokeTokenShareAnalysisResultDialogBlock:(BDUGTokenShareAnalysisResultModel *)resultModel {
    [[BDUGTokenShareDialogManager sharedManager] invokeTokenShareAnalysisResultDialogBlock:resultModel];
}

+ (void)shareToken:(BDUGTokenShareInfo *)tokenModel {
    [BDUGShareEventManager event:kSharePopupClick params:@{
        @"channel_type" : (tokenModel.channelStringForEvent ?: @""),
        @"share_type" : @"token",
        @"popup_type" : @"go_share",
        @"click_result" : @"submit",
        @"panel_type" : (tokenModel.panelType ?: @""),
        @"panel_id" : (tokenModel.panelId ?: @""),
        @"resource_id" : (tokenModel.groupID ?: @""),
    }];
    if (tokenModel.tokenDesc) {
        [UIPasteboard generalPasteboard].string = tokenModel.tokenDesc;
    }
    [BDUGTokenShareDialogManager sharedManager].lastShareToken = tokenModel.tokenDesc;
    BOOL isOpenSuccess = NO;
    NSString *errorDesc = @"";
    if (tokenModel.openThirdPlatformBlock) {
        isOpenSuccess = tokenModel.openThirdPlatformBlock();
    }
    if (!isOpenSuccess) {
        errorDesc = @"无法打开应用";
    }
    if (isOpenSuccess && tokenModel.completeBlock) {
        tokenModel.completeBlock(BDUGTokenShareStatusCodeSuccess, nil);
    } else if (!isOpenSuccess && tokenModel.completeBlock) {
        tokenModel.completeBlock(BDUGTokenShareStatusCodePlatformOpenFailed, errorDesc);
    }
}

+ (void)cancelTokenShare:(BDUGTokenShareInfo *)tokenModel {
    [BDUGShareEventManager event:kSharePopupClick params:@{
                                                 @"channel_type" : (tokenModel.channelStringForEvent ?: @""),
                                                 @"share_type" : @"token",
                                                 @"popup_type" : @"go_share",
                                                 @"click_result" : @"cancel",
                                                 @"panel_type" : (tokenModel.panelType ?: @""),
                                                 @"panel_id" : (tokenModel.panelId ?: @""),
                                                 @"resource_id" : (tokenModel.groupID ?: @""),
                                                 }];
    if (tokenModel.completeBlock) {
        tokenModel.completeBlock(BDUGTokenShareStatusCodeUserCancel, @"");
    }
}

+ (void)setLastToken:(NSString *)token {
    [BDUGTokenShareDialogManager sharedManager].lastShareToken = token;
}

#pragma mark -

+ (instancetype)sharedManager {
    static BDUGTokenShareDialogManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self class] new];
    });
    return sharedManager;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init {
    if (self = [super init]) {

    }
    return self;
}

- (void)registerTokenAnalysisWithNotificationName:(NSString *)notificationName
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[BDUGShareSettingsUtil sharedInstance] settingsWithKey:kBDUGShareSettingsKeyTokenParse handler:^(BOOL settingStatus) {
            if (settingStatus) {
                NSString *notiName = notificationName;
                if (notiName.length == 0) {
                    notiName = UIApplicationWillEnterForegroundNotification;
                }
                
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForeground) name:notiName object:nil];
                [self appEnterForeground];
            } else {
                [BDUGLogger logMessage:@"口令解析setting关闭" withLevType:BDUGLoggerInfoType];
            }
        }];
    });
}

- (void)invokeTokenShareDialogBlock:(BDUGTokenShareInfo *)tokenModel {
    if (_additionalShareDialogs.count > 0) {
        //避免出现懒加载。
        __block BOOL hitAdditionalRegister = NO;
        [_additionalShareDialogs enumerateObjectsUsingBlock:^(BDUGAdditionalTokenShareDialogBlock  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           if (obj && obj(tokenModel)) {
               hitAdditionalRegister = YES;
               *stop = YES;
           }
        }];
        if (hitAdditionalRegister) {
            //命中拓展注册，不调用通用注册。
            return;
        }
    }
    
    if (_tokenShareDialogBlock) {
        _tokenShareDialogBlock(tokenModel);
        [BDUGShareEventManager event:kSharePopupShow params:@{
                                                    @"channel_type" : (tokenModel.channelStringForEvent ?: @""),
                                                    @"popup_type" : @"go_share",
                                                    @"share_type" : @"token",
                                                    @"panel_type" : (tokenModel.panelType ?: @""),
                                                    @"panel_id" : (tokenModel.panelId ?: @""),
                                                    @"resource_id" : (tokenModel.groupID ?: @""),
                                                    }];
    } else {
        NSAssert(0, @"口令分享功能缺失。详见文档。\
                 自定义分享UI：实现tokenShareRegisterDialogBlock。\
                 使用默认UI：\
                    1、引入subspec: BDUGShareUI/Token/TextToken\
                    2、调用BDUGTokenShareDialogService相关方法。");
    }
}

- (void)invokeTokenShareAnalysisResultDialogBlock:(BDUGTokenShareAnalysisResultModel *)resultModel {
    if (_additionalAnalysisDialogs.count > 0) {
        //避免出现懒加载。
        __block BOOL hitAdditionalRegister = NO;
        [_additionalAnalysisDialogs enumerateObjectsUsingBlock:^(BDUGAdditionalTokenShareAnalysisResultBlock  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           if (obj && obj(resultModel)) {
               hitAdditionalRegister = YES;
               *stop = YES;
           }
        }];
        if (hitAdditionalRegister) {
            //命中拓展注册，不调用通用注册。
            return;
        }
    }
    if (_tokenAnalysisDialogBlock) {
        _tokenAnalysisDialogBlock(resultModel);
    }
}

#pragma mark - 解析粘贴板

- (void)appEnterForeground {
    [self handleTokenResult];
}

- (void)getTokenFromPasteboard:(void (^)(NSString *token))complete {
    if (!complete) {
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *token = [[UIPasteboard generalPasteboard] string];
        dispatch_async(dispatch_get_main_queue(), ^{
            complete(token);
        });
    });
}

- (void)handleTokenResult {
    NSString *tokenRegex = [self tokenShareValidRegex];
    if (isEmptyString(tokenRegex)) {
        BDUGLoggerInfo(@"setting没有下发口令正则式");
        return;
    }
    
     /*
    todo：这里寻求替代。
    todo：剪切板卡死的问题埋点
    // flag=1说明上一次卡死
    NSNumber *flag = [[NSUserDefaults standardUserDefaults] objectForKey:kBDUGTokenSharePasteboardLastState];
    if (flag) {
        BOOL success = [flag integerValue] == 0;
        BOOL async = [[NSUserDefaults standardUserDefaults] boolForKey:kBDUGTokenSharePasteboardLastAsync];// 上一次是否异步处理
        [[TTMonitor shareManager] trackService:@"token_share_pasteboard_last_status" status:success ? 0 : 1 extra:@{@"async" : @(async)}];
        if (!success) {
            BDUGShare_ErrorLog(@"上一次剪贴板卡死 async : %@", @(async));
        }
    }
    */
    
    // 设置标记
    [[NSUserDefaults standardUserDefaults] setValue:@(1) forKey:kBDUGTokenSharePasteboardLastState];
    
    //todo: 剪切板卡死的问题埋点。
//    [[NSUserDefaults standardUserDefaults] setValue:@([[TTSettingsManager sharedManager] isAsyncReadPasteboardEnable]) forKey:kBDUGTokenSharePasteboardLastAsync];
    
//    int64_t startTime = [NSDate date].timeIntervalSince1970 * 1000;
    __weak typeof(self) wself = self;
    [self getTokenFromPasteboard:^(NSString *token) {
        if (self.tokenShouldAnalysisBlock && !self.tokenShouldAnalysisBlock(token)) {
            //实现了should回调并且返回了no，则不进行口令识别。
            return ;
        }
        
        __strong typeof(wself) strongSelf = wself;
        
//        int64_t endTime = [NSDate date].timeIntervalSince1970 * 1000;
        //todo：这里寻求替代。
//        [[TTMonitor shareManager] trackService:@"token_share_pasteboard_time" value:@(endTime - startTime) extra:@{@"token" : token ?: @"", @"async" : @([[TTSettingsManager sharedManager] isAsyncReadPasteboardEnable])}];
        
        // 重置标记
        [[NSUserDefaults standardUserDefaults] setValue:@(0) forKey:kBDUGTokenSharePasteboardLastState];
        
        if (isEmptyString(token)) {
            BDUGLoggerInfo(@"口令为空");
            return;
        }
        
        NSRange range = [token rangeOfString:tokenRegex options:NSRegularExpressionSearch];
        if (range.location == NSNotFound) {
            BDUGLoggerInfo(@"正则式和口令不匹配");
            return;
        }
        
        BDUGLoggerInfo(([NSString stringWithFormat:@"口令 : %@", token]));
        
        //即分享者不识别自己的口令。杀死程序后会识别。
        if ([strongSelf.lastShareToken isEqualToString:token]) {
            BDUGLoggerInfo(@"与上一次分享一致，不处理");
            //清空剪贴板。
            [UIPasteboard generalPasteboard].string = @"";
            strongSelf.lastShareToken = nil;
            return;
        }
        
        NSString *subToken = [token substringWithRange:range];
        if (!subToken) {
            subToken = token;
        }
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:2];
        [params setValue:subToken forKey:@"token"];
        
        __weak typeof(strongSelf) wself1 = strongSelf;
        NSString *requestURLString = [[BDUGShareSequenceManager sharedInstance].configuration.hostString stringByAppendingString:[self tokenAnalysisPath]];
        [[TTNetworkManager shareInstance] requestForJSONWithURL:requestURLString params:params method:@"GET" needCommonParams:YES  requestSerializer:[TTDefaultHTTPRequestSerializer class] responseSerializer:[TTHTTPJSONResponseSerializerBase class] autoResume:YES callback:^(NSError *error, id jsonObj) {
            BOOL succeed = NO;
            NSString *groupType = @"token";
            NSString *failedReason = @"";
            __strong typeof(wself1) strongSelf1 = wself1;
            if (error == nil && [jsonObj isKindOfClass:[NSDictionary class]]) {
                NSInteger status = [(NSDictionary *)jsonObj btd_intValueForKey:@"status"];
                if ([(NSDictionary *)jsonObj objectForKey:@"status"] != nil && status == 0) {
                    //口令识别成功，清空剪切板
                    [UIPasteboard generalPasteboard].string = @"";
                    NSDictionary *data = [(NSDictionary *)jsonObj btd_dictionaryValueForKey:@"data"];
                    BDUGTokenShareAnalysisResultModel *model = [[BDUGTokenShareAnalysisResultModel alloc] initWithDict:data];
                    model.groupTypeForEvent = groupType;
                    [strongSelf1 invokeTokenShareAnalysisResultDialogBlock:model];
                    succeed = YES;
                } else if (status == 2) {
                    BDUGLoggerError(@"口令失效");
                    //口令过期失效，清空剪切板。
                    [UIPasteboard generalPasteboard].string = @"";
                    [strongSelf1 invokeTokenShareAnalysisResultDialogBlock:nil];
                    failedReason = @"expired";
                } else if (status == 1001) {
                    BDUGLoggerError(@"口令与应用不匹配");
                    failedReason = @"other_app";
                } else {
                    BDUGLoggerInfo(@"不处理口令");
                    failedReason = @"failed";
                }
            } else {
                BDUGLoggerError(([NSString stringWithFormat:@"口令分享接口错误, error : %@", error.description]));
                failedReason = @"failed";
            }
            [BDUGShareEventManager event:kShareEventRecognizeInterfaceRequest params:@{
                                                                             @"recognize_type" : groupType,
                                                                             @"is_success" : (succeed ? @"success" : @"failed"),
                                                                             @"failed_reason" : failedReason,
                                                                             }];
            [BDUGShareEventManager trackService:kShareMonitorTokenInfo attributes:@{@"status" : (succeed ? @(0) : @(1))}];
        }];
    }];
}

#pragma mark - help

- (NSString *)tokenShareValidRegex {
    //token regex, hard code for the key;
    NSString *tokenRegex = [[NSUserDefaults standardUserDefaults] stringForKey:@"BDUGShareTokenRegex"];
    return tokenRegex;
}

- (NSString *)tokenAnalysisPath {
    return @"ug_token/info/v1/";
}

#pragma mark - set & get
- (NSString *)lastShareToken {
    if (!_lastShareToken) {
        // 只需要读取一次
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            self->_lastShareToken = [[NSUserDefaults standardUserDefaults] stringForKey:kBDUGTokenShareLastShareTokenKey];
        });
    }
    return _lastShareToken;
}

- (void)setLastShareToken:(NSString *)lastShareToken {
    _lastShareToken = lastShareToken;
    [[NSUserDefaults standardUserDefaults] setObject:_lastShareToken forKey:kBDUGTokenShareLastShareTokenKey];
}

- (NSMutableArray<BDUGAdditionalTokenShareDialogBlock> *)additionalShareDialogs {
    if (!_additionalShareDialogs) {
        _additionalShareDialogs = [[NSMutableArray alloc] init];
    }
    return _additionalShareDialogs;
}

- (NSMutableArray<BDUGAdditionalTokenShareAnalysisResultBlock> *)additionalAnalysisDialogs {
    if (!_additionalAnalysisDialogs) {
        _additionalAnalysisDialogs = [[NSMutableArray alloc] init];
    }
    return _additionalAnalysisDialogs;
}

#pragma mark - operate analysis

+ (void)beginTokenAnalysis
{
    [[BDUGTokenShareDialogManager sharedManager] handleTokenResult];
}

@end
