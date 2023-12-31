//
//  BDPShareManager.m
//  Timor
//
//  Created by MacPu on 2018/12/29.
//

#import "BDPShareManager.h"
#import <OPFoundation/BDPCommon.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/BDPNetworking.h>
#import <OPFoundation/BDPSDKConfig.h>
#import <OPFoundation/BDPSchemaCodec+Private.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPTracker.h>
#import <OPFoundation/BDPUserAgent.h>
#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/TMACustomHelper.h>
#import <OPFoundation/TMASessionManager.h>
#import <ECOInfra/NSURLSession+TMA.h>

#import <OPSDK/OPSDK-Swift.h>
#import <LarkStorage/LarkStorage-Swift.h>

static const CGFloat kShareImgMaxSize = 2048.0; // 分享图片最大大小，单位kB，若大于此值则使用服务端返回默认图片
static const CGFloat kShareImgCompressSize = 200; // 分享图片大于此值才做压缩，单位kB
static const CGFloat kShareImgUploadTimeout = 6; // 单位：秒
static NSString *const kOSType = @"ios";
static NSString *const kShareChannel = @"share_channel";
static NSString *const kContentType = @"content_type";
static NSString *const kShareResult = @"share_result";
static NSString *const kErrMsgKey = @"share_errmsg";

@interface BDPShareManager ()

@property (nonatomic, assign) BDPShareEntryType shareEntry;
@property (nonatomic, assign) BOOL isShareFromToolBar;
@property (nonatomic, copy) NSString *deviceID;
@property (nonatomic, strong) BDPShareContext *shareContext;
@property (nonatomic, copy) BDPGetShareInfoCallback getShareInfoCB;
@property (nonatomic, copy) BDPGetDefaultShareInfoCallback getDefaultShareInfoCB;
@property (nonatomic, assign) NSTimeInterval shareStartTime;
@property (atomic, assign) BOOL requesting;
@property (nonatomic, strong) BDPSharePluginModel *shareModel;

@end

@implementation BDPShareManager

+ (instancetype)sharedManager
{
    static BDPShareManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[BDPShareManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        BDPPlugin(userPlugin, BDPUserPluginDelegate);
        if ([userPlugin respondsToSelector:@selector(bdp_deviceId)]) {
            _deviceID = [[userPlugin bdp_deviceId] copy];
        }
    }
    return self;
}

///  ShareEntry - 分享调起入口
- (void)setShareEntry:(BDPShareEntryType)shareEntry
{
    if (_shareEntry != shareEntry) {    // 为区分分享入口
        if (shareEntry == BDPShareEntryTypeToolBar) {
            _shareEntry = shareEntry;
            _isShareFromToolBar = YES;
        } else if (shareEntry == BDPShareEntryTypeInner) {
            if (_isShareFromToolBar == NO) {
                _shareEntry = BDPShareEntryTypeInner;
            }
            _isShareFromToolBar = NO;
        } else {
            _shareEntry = shareEntry;
        }
    }
}

/// 埋点
- (void)eventShareTrackerWithName:(NSString *)event extraParam:(NSDictionary *)extraParam
{
    BDPShareContext *context = _shareContext;
    BDPCommon *common = context.appCommon;

    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    [param setValue:common.model.uniqueID.appID forKey:BDPTrackerAppIDKey];
    [param setValue:context.query forKey:@"page_path"];
    if (_shareEntry == BDPShareEntryTypeToolBar) {
        [param setValue:@"top" forKey:@"position"];
    } else if (_shareEntry == BDPShareEntryTypeInner) {
        [param setValue:@"inside" forKey:@"position"];
    }
    NSString *shareType = [context.channel isEqualToString:@"token"] ? @"token" : @"link";
    [param setValue:shareType forKey:@"share_type"];
    
    NSString *shareChannel = [extraParam bdp_stringValueForKey:kShareChannel];
    [param setValue:shareChannel forKey:@"platform"];
    
    NSString *errMsg = [extraParam bdp_stringValueForKey:kErrMsgKey] ?: @"";

    if ([event isEqualToString:@"mp_share_window"] || [event isEqualToString:@"mp_share_upload"]) {
        NSUInteger duration = ([[NSDate date] timeIntervalSince1970] - _shareStartTime) * 1000;
        BOOL isShareSuccess = [extraParam bdp_boolValueForKey:kShareResult];
        [param setValue:@(duration) forKey:BDPTrackerDurationKey];
        [param setValue:errMsg forKey:BDPTrackerErrorMsgKey];
        [param setValue:isShareSuccess ? BDPTrackerResultSucc : BDPTrackerResultFail forKey:BDPTrackerResultTypeKey];
        if (duration > kShareImgUploadTimeout * 1000) {
            [param setValue:BDPTrackerResultTimeout forKey:BDPTrackerResultTypeKey];
        }
    } else if ([event isEqualToString:@"mp_share_result"]) {
        NSString *shareResult = [extraParam bdp_stringValueForKey:kShareResult];
        [param setValue:errMsg forKey:BDPTrackerErrorMsgKey];
        [param setValue:shareResult forKey:BDPTrackerResultTypeKey];
    }

    [BDPTracker event:event attributes:param uniqueID:common.uniqueID];
}

- (void)eventPublishWithName:(NSString *)event extra:(NSDictionary *)extraDict
{
    NSMutableDictionary *param = [NSMutableDictionary dictionaryWithCapacity:2];
    if (extraDict.count) {
        [param addEntriesFromDictionary:extraDict];
    }
    if (_shareContext.channel) {
        [param setValue:_shareContext.channel forKey:kContentType];
    }

    NSString *position = @"inside";
    if (_shareEntry == BDPShareEntryTypeToolBar) {
        position = @"top";
    }
    [param setValue:position forKey:@"position"];
    
    [BDPTracker event:event attributes:param uniqueID:_shareContext.appCommon.uniqueID];
}

- (void)onShareBegin:(BDPShareContext *)context
{
    self.shareContext = context;
    self.getShareInfoCB = nil;
    self.getDefaultShareInfoCB = nil;
    self.shareStartTime = [[NSDate date] timeIntervalSince1970];
    [self uploadShareImg];
    
    NSString *channel = _shareContext.channel;
    
    if (BDPIsEmptyString(channel) || [channel isEqualToString:@"token"]) {
        [self eventShareTrackerWithName:@"mp_share_click" extraParam:nil];
    } else {
        NSMutableDictionary *extraDict = [NSMutableDictionary dictionaryWithCapacity:2];
        extraDict[@"alias_id"] = context.extra[@"alias_id"] ?: @"";
        extraDict[@"filter_type"] = context.extra[@"filter_type"] ?: @"";
        [self eventPublishWithName:@"mp_publish_click" extra:extraDict];
    }
    
}

- (void)onShareDone:(BDPShareResultType)result errMsg:(NSString *)errMsg
{
    NSString *channel = _shareContext.channel;
    
    if (BDPIsEmptyString(channel) || [channel isEqualToString:@"token"]) {
        NSString *shareResult = [self bdpShareResultToStr:result];
        [self eventShareTrackerWithName:@"mp_share_result"
                             extraParam:@{kShareChannel : _shareContext.shareChannel ?: @"",
                                          kShareResult : shareResult,
                                          kErrMsgKey : errMsg ?: @""}];
    } else {
        NSMutableDictionary *extraDict = [NSMutableDictionary dictionaryWithCapacity:2];
        extraDict[@"alias_id"] = _shareContext.extra[@"alias_id"] ?: @"";
        extraDict[@"filter_type"] = _shareContext.extra[@"filter_type"] ?: @"";
        extraDict[@"filter_result"] = _shareContext.extra[@"filter_result"] ?: @"";
        [self eventPublishWithName:@"mp_publish_done" extra:extraDict];
    }
    
    if (result != BDPShareResultTypeSuccess) {
        [self cleanUselessData];
    }
}

-(void)uploadShareImg
{
    BDPCommon *common = _shareContext.appCommon;
    NSString *imageUrl = _shareContext.imageUrl;
    NSDictionary *params = @{
                               @"host_id": @(BDPHostAppId()),
                               @"app_id": common.uniqueID.appID ?: @"",
                               @"image_url": imageUrl ?: @"",
                               @"os": kOSType,
                               @"did": _deviceID ?: @""
                               };
    NSData *imgData = nil;
    
    if ([imageUrl hasPrefix:@"file://"]) {
        imageUrl = [imageUrl componentsSeparatedByString:@"file://"][1];
        imgData = [NSData lss_dataWithContentsOfFile:imageUrl error:nil];
        if (imgData.length / 1024.0 > kShareImgCompressSize) {
            imgData = UIImageJPEGRepresentation([UIImage imageWithContentsOfFile:imageUrl], 0.6);
            if (imgData && ((imgData.length / 1024.0) > kShareImgMaxSize)) {
                imgData = nil;
            }
        }
    }
    BDPNetworkRequestExtraConfiguration* config = [BDPNetworkRequestExtraConfiguration defaultConfig];
    config.flags = BDPRequestAutoResume;
    config.type = BDPRequestTypeUpload;
    config.timeout = kShareImgUploadTimeout;
    config.constructingBodyBlock = ^(id<TTMultipartFormData> formData) {
        if (imgData) {
            [formData appendPartWithFileData:imgData name:@"image_file" fileName:[imageUrl lastPathComponent] mimeType:@"image/jpeg"];
        }
    };
    
    BDPLogTagInfo(@"ShareManager", @"uploadImgBegin, app=%@", common.uniqueID);
    WeakSelf;
    [BDPNetworking taskWithRequestUrl:[BDPSDKConfig sharedConfig].shareImgUploadURL parameters:params extraConfig:config completion:^(NSError *error, id obj, id<BDPNetworkResponseProtocol> response) {
        StrongSelfIfNilReturn;
        [self handleUploadImgResponse:error data:obj];
    }];
}

- (void)handleUploadImgResponse:(NSError *)err data:(id)data
{
    if (!err && data) {
        BDPLogInfo(@"handleUploadImgResponse success")
        NSDictionary * jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        if (!err) {
            NSInteger errNo = [jsonObj bdp_intValueForKey:@"err_no"];
            if (errNo == 0) {
                NSDictionary *dataDic = [jsonObj bdp_dictionaryValueForKey:@"data"];
                self.shareContext.imgURI = [dataDic bdp_stringValueForKey:@"uri"];
            } else {
                self.shareContext.imgURI = @""; //URI为空服务端返回默认图片
                NSString *msg = [jsonObj bdp_stringValueForKey:@"message"];
                err = BDPErrorWithMessage(msg);
            }
        } else {
            self.shareContext.imgURI = @""; //URI为空服务端返回默认图片
            BDPLogWarn(@"handleUploadImgResponse fail, err=%@", err);
        }
    } else {
        BDPLogWarn(@"handleUploadImgResponse fail, err=%@", err);
        self.shareContext.imgURI = @""; //URI为空服务端返回默认图片
    }
    
    [self eventShareTrackerWithName:@"mp_share_upload"
                         extraParam:@{kShareChannel : _shareContext.shareChannel ?: @"",
                                      kShareResult : @(!err),
                                      kErrMsgKey : err.localizedDescription ?: @""}];
    
    if (_getDefaultShareInfoCB) {
        [self requestDefaultShareMsg];
    }
    
    if (_getShareInfoCB) {
        [self requestShareMsg];
    }
}

- (void)requestDefaultShareMsg
{
    BDPCommon *common = _shareContext.appCommon;
    NSDictionary *params = @{
                             @"host_id": @(BDPHostAppId()),
                             @"app_id": common.uniqueID.appID ?: @"",
                             @"query": _shareContext.query ?: @"",
                             @"title": _shareContext.title ?: @"",
                             @"share_channel": _shareContext.shareChannel ?: @"",
                             @"channel": _shareContext.channel ?: @"",
                             @"session": [[TMASessionManager sharedManager] getSession:common.sandbox] ?: @"",
                             @"os": kOSType,
                             @"did": _deviceID ?: @"",
                             @"uri": _shareContext.imgURI ?: @"",
                             @"share_extra": @{@"link_title": _shareContext.linkTitle ?: @""},
                             @"templateId": _shareContext.templateId ?: @"",
                             @"description": _shareContext.desc ?: @""
                             };
    
    BDPLogInfo(@"requestDefaultShareMsgBegin, app=%@", common.uniqueID);
    WeakSelf;
    NSMutableDictionary *headerFieldDict = [NSMutableDictionary dictionary];
    headerFieldDict[@"User-Agent"] = [BDPUserAgent getUserAgentString];
    BDPNetworkRequestExtraConfiguration* config = [BDPNetworkRequestExtraConfiguration defaultBDPSerializerConfigWithHttpMethod:BDPRequestMethodPOST];
    config.flags = BDPRequestAutoResume | BDPRequestCallbackInMainThread;
    config.bdpRequestHeaderField = headerFieldDict;
    
    [BDPNetworking taskWithRequestUrl:[BDPSDKConfig sharedConfig].shareDefaultMsgURL parameters:params extraConfig:config completion:^(NSError *error, id jsonObj, id<BDPNetworkResponseProtocol> response) {
        
        StrongSelfIfNilReturn;
        if (error) {
            BDPLogWarn(@"request default share msg fail, app=%@, error=%@", common.uniqueID, error);
        } else {
            BDPLogInfo(@"request default share msg success, app=%@", common.uniqueID);
        }
        [self handleDefaultShareMsgResponse:jsonObj error:error];
    }];
}

/// 处理获取token返回的数据
- (void)handleDefaultShareMsgResponse:(NSDictionary *)response error:(NSError *)error
{
    self.requesting = NO;
    [self eventShareTrackerWithName:@"mp_share_window"
                         extraParam:@{kShareChannel : _shareContext.shareChannel ?: @"",
                                      kShareResult : @(!error),
                                      kErrMsgKey : error.localizedDescription ?: @""}];
    
    BDPGetDefaultShareInfoCallback complete = _getDefaultShareInfoCB;
    
    if (error || BDPIsEmptyDictionary(response)) {
        [TMACustomHelper hideCustomLoadingToast:self.shareContext.appCommon.uniqueID.window];
        [TMACustomHelper showCustomToast:BDPI18n.share_fail_and_try icon:nil window:self.shareContext.appCommon.uniqueID.window];
        !complete ?: complete(nil, BDPErrorWithMessage(@"Request token failed."));
        return;
    }
    
    NSInteger responseErrNumber = [response bdp_integerValueForKey:@"err_no"];
    NSString *responseErrMessage = [response bdp_stringValueForKey:@"message"];
    if (responseErrNumber != 0) {
        [TMACustomHelper hideCustomLoadingToast:self.shareContext.appCommon.uniqueID.window];
        [TMACustomHelper showCustomToast:BDPI18n.share_fail_and_try icon:nil window:self.shareContext.appCommon.uniqueID.window];
        !complete ?: complete(nil, BDPErrorWithMessage(responseErrMessage ?: @"TMA Service Unavailable."));
        return;
    }
    
    // Check Data Valid
    NSDictionary *responseData = [response bdp_dictionaryValueForKey:@"data"];
    if (!responseData) {
        [TMACustomHelper hideCustomLoadingToast:self.shareContext.appCommon.uniqueID.window];
        [TMACustomHelper showCustomToast:BDPI18n.share_fail_and_try icon:nil window:self.shareContext.appCommon.uniqueID.window];
        !complete ?: complete(nil, BDPErrorWithMessage(responseErrMessage ?:@"Response Data is NULL."));
        return;
    }
    
    // Get Data From Response
    NSString *responsetitle = [responseData bdp_stringValueForKey:@"title"];
    NSString *responseImageUrl = [responseData bdp_stringValueForKey:@"image_url"];
    NSString *responseDescription = [responseData bdp_stringValueForKey:@"description"];
    
    BDPSharePluginModel *shareModel = [[BDPSharePluginModel alloc] init];
    shareModel.title = responsetitle;
    shareModel.imageUrl = responseImageUrl;
    shareModel.desc = responseDescription;
    
    if ([[BDPTimorClient sharedClient] currentNativeGlobalConfiguration].shouldDismissShareLoading) {
        [TMACustomHelper hideCustomLoadingToast:self.shareContext.appCommon.uniqueID.window];
    }
    
    !complete ?: complete(shareModel, nil);
}

- (void)requestShareMsg
{
    BDPCommon *common = _shareContext.appCommon;
    NSDictionary *params = @{
                             @"host_id": @(BDPHostAppId()),
                             @"app_id": common.uniqueID.appID ?: @"",
                             @"query": _shareContext.query ?: @"",
                             @"title": _shareContext.title ?: @"",
                             @"share_channel": _shareContext.shareChannel ?: @"",
                             @"channel": _shareContext.channel ?: @"",
                             @"session": [[TMASessionManager sharedManager] getSession:common.sandbox] ?: @"",
                             @"os": kOSType,
                             @"did": _deviceID ?: @"",
                             @"uri": _shareContext.imgURI ?: @"",
                             @"share_extra": @{@"link_title": _shareContext.linkTitle ?: @""},
                             @"templateId": _shareContext.templateId ?: @"",
                             @"description": _shareContext.desc ?: @""
                             };
    
    BDPLogInfo(@"requestShareMsgBegin, app=%@", common.uniqueID);
    WeakSelf;
    NSMutableDictionary *headerFieldDict = [NSMutableDictionary dictionary];
    headerFieldDict[@"User-Agent"] = [BDPUserAgent getUserAgentString];
    BDPNetworkRequestExtraConfiguration* config = [BDPNetworkRequestExtraConfiguration defaultBDPSerializerConfigWithHttpMethod:BDPRequestMethodPOST];
    config.flags = BDPRequestAutoResume | BDPRequestCallbackInMainThread;
    config.bdpRequestHeaderField = headerFieldDict;
    
    [BDPNetworking taskWithRequestUrl:[BDPSDKConfig sharedConfig].shareMsgURL parameters:params extraConfig:config completion:^(NSError *error, id jsonObj, id<BDPNetworkResponseProtocol> response) {
        
        StrongSelfIfNilReturn;
        if (error) {
            BDPLogWarn(@"request share msg fail, app=%@, error=%@", common.uniqueID, error);
        } else {
            BDPLogInfo(@"request share msg success, app=%@", common.uniqueID);
        }
        [self handleShareMsgResponse:jsonObj error:error];
    }];
}

/// 处理获取token返回的数据
- (void)handleShareMsgResponse:(NSDictionary *)response error:(NSError *)error
{
    self.requesting = NO;
    [self eventShareTrackerWithName:@"mp_share_window"
                         extraParam:@{kShareChannel : _shareContext.shareChannel ?: @"",
                                      kShareResult : @(!error),
                                      kErrMsgKey : error.localizedDescription ?: @""}];
    
    BDPGetShareInfoCallback complete = _getShareInfoCB;
    
    if (error || BDPIsEmptyDictionary(response)) {
        [TMACustomHelper hideCustomLoadingToast: self.shareContext.appCommon.uniqueID.window];
        [TMACustomHelper showCustomToast:BDPI18n.share_fail_and_try icon:nil window:self.shareContext.appCommon.uniqueID.window];
        !complete ?: complete(nil, BDPErrorWithMessage(@"Request token failed."));
        return;
    }
    
    NSInteger responseErrNumber = [response bdp_integerValueForKey:@"err_no"];
    NSString *responseErrMessage = [response bdp_stringValueForKey:@"message"];
    if (responseErrNumber != 0) {
        [TMACustomHelper hideCustomLoadingToast:self.shareContext.appCommon.uniqueID.window];
        [TMACustomHelper showCustomToast:BDPI18n.share_fail_and_try icon:nil window:self.shareContext.appCommon.uniqueID.window];
        !complete ?: complete(nil, BDPErrorWithMessage(responseErrMessage ?: @"TMA Service Unavailable."));
        return;
    }
    
    // Check Data Valid
    NSDictionary *responseData = [response bdp_dictionaryValueForKey:@"data"];
    if (!responseData) {
        [TMACustomHelper hideCustomLoadingToast:self.shareContext.appCommon.uniqueID.window];
        [TMACustomHelper showCustomToast:BDPI18n.share_fail_and_try icon:nil window:self.shareContext.appCommon.uniqueID.window];
        !complete ?: complete(nil, BDPErrorWithMessage(responseErrMessage ?:@"Response Data is NULL."));
        return;
    }
    
    // Get Data From Response
    NSString *responseImageUrl = [responseData bdp_stringValueForKey:@"image_url"];
    NSString *responseMiniImageUrl = [responseData bdp_stringValueForKey:@"mini_image_url"];
    NSString *responsetitle = [responseData bdp_stringValueForKey:@"title"];
    NSString *responseToken = [responseData bdp_stringValueForKey:@"token"];
    NSString *responseUGURL = [responseData bdp_stringValueForKey:@"ug_url"];
    NSDictionary *extra = [responseData bdp_dictionaryValueForKey:@"share_extra"];
    NSString *linkTitle = [extra bdp_stringValueForKey:@"link_title"];
    NSString *responseDescription = [responseData bdp_stringValueForKey:@"description"];
    
    BDPCommon *common = _shareContext.appCommon;
    
    BDPSharePluginModel *shareModel = [[BDPSharePluginModel alloc] init];
    self.shareModel = shareModel;
    shareModel.imageUrl = responseImageUrl;
    shareModel.miniImageUrl = responseMiniImageUrl;
    shareModel.title = responsetitle;
    shareModel.token = responseToken;
    shareModel.ugUrl = responseUGURL;
    shareModel.appId = common.uniqueID.appID;
    shareModel.appName = !BDPIsEmptyString(linkTitle) ? linkTitle : common.model.name;
    shareModel.appIcon = common.model.icon;
    shareModel.appType = (BDPShareAppType)common.uniqueID.appType;
    shareModel.query = _shareContext.query;
    shareModel.extra = extra;
    shareModel.withShareTicket = _shareContext.withShareTicket;
    shareModel.desc = responseDescription;
    
    BDPPlugin(sharePlugin, BDPSharePluginDelegate);
    NSString *schemaProxy = @"sslocal";
    
    NSString *schemaHost = SCHEMA_APP;
    
    // 2019-4-22 修改为V2版本的schema
    BDPSchemaCodecOptions *schemaOptions = [[BDPSchemaCodecOptions alloc] init];
    [schemaOptions setProtocol:schemaProxy];
    [schemaOptions setHost:schemaHost];
    [schemaOptions setAppID:_shareContext.appCommon.uniqueID.appID];
    [schemaOptions setVersionType:_shareContext.appCommon.schema.versionType];
    [schemaOptions setToken:_shareContext.appCommon.schema.token];
    [schemaOptions setFullStartPage:_shareContext.query];
    
    NSError *schemaError = nil;
    NSString *schemaString = [BDPSchemaCodec schemaStringFromCodecOptions:schemaOptions error:&schemaError];
    if (schemaError != nil) {
        //为了保持分享到可靠性,一旦V2版本拼接失败,改用旧版逻辑重试
        NSString *schema = [NSString stringWithFormat:@"%@://%@?app_id=%@", schemaProxy, schemaHost, _shareContext.appCommon.uniqueID.appID];
        if (_shareContext.query) {
            schema = [schema stringByAppendingString:@"&start_page="];
            schema = [schema stringByAppendingString:_shareContext.query];
        }
        schemaString = schema;
    }
    
    shareModel.schema = schemaString;
    
    if ([[BDPTimorClient sharedClient] currentNativeGlobalConfiguration].shouldDismissShareLoading) {
        [TMACustomHelper hideCustomLoadingToast:common.uniqueID.window];
    }
    
    !complete ?: complete(shareModel, nil);
}

- (void)cleanUselessData {
    if (!self.shareModel) {
        return;
    }
    
    BDPCommon *common = _shareContext.appCommon;
    NSDictionary *params = @{
                             @"host_id": @(BDPHostAppId()),
                             @"app_id": BDPSafeString(common.uniqueID.appID),
                             @"os": kOSType,
                             @"session": BDPSafeString([[TMASessionManager sharedManager] getSession:common.sandbox]),
                             @"did": BDPSafeString(_deviceID),
                             @"share_token": BDPSafeString(self.shareModel.token),
                             };
    NSDictionary *headerFieldDict = @{
        @"User-Agent": BDPSafeString([BDPUserAgent getUserAgentString])
    };
    BDPNetworkRequestExtraConfiguration *config = [BDPNetworkRequestExtraConfiguration defaultBDPSerializerConfigWithHttpMethod:BDPRequestMethodPOST];
    config.bdpRequestHeaderField = headerFieldDict;
    
    WeakSelf;
    [BDPNetworking taskWithRequestUrl:[BDPSDKConfig sharedConfig].deleteShareDataURL parameters:params extraConfig:config completion:^(NSError *error, id jsonObj, id<BDPNetworkResponseProtocol> response) {
        StrongSelfIfNilReturn;
        self.shareModel = nil;
    }];
}

#pragma mark - Util

- (NSString *)bdpShareResultToStr:(BDPShareResultType)result
{
    NSString *resultStr = @"";
    switch (result) {
        case BDPShareResultTypeSuccess:
            resultStr = BDPTrackerResultSucc;
            break;
            
        case BDPShareResultTypeCancel:
            resultStr = BDPTrackerResultCancel;
            break;
            
        default:
            resultStr = BDPTrackerResultFail;
            break;
    }
    return resultStr;
}

@end
