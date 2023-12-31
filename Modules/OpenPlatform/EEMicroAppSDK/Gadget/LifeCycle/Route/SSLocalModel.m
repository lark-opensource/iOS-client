//
//  SSLocalModel.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/23.
//

#import "SSLocalModel.h"
#import <OPFoundation/NSURL+EMA.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPUniqueID.h>
#import <OPFoundation/BDPSchemaCodec.h>
#import <OPFoundation/NSURLComponents+EMA.h>

static NSString * const kHostMicroApp = @"microapp";
static NSString * const kHostMiniProgram = @"mini-program";

static NSString * const kPathDpdtLog = @"/mpdt/log";

static NSString * const kAppId = @"app_id";
NSString * const kIsDev = @"isdev"; // preview 相关
static NSString * const kStartPage = @"start_page";
static NSString * const kRefererInfo = @"refererInfo";
static NSString * const kUseCache = @"useCache";
NSString * const kBdpLaunchQueryKey = @"bdp_launch_query";
NSString * const kBdpLaunchRequestAbilityKey = @"required_launch_ability";
static NSString * const kScene = @"scene";
NSString * const kVersionType = @"version_type"; // current or preview
//端上的止血配置 https://bytedance.feishu.cn/docs/doccnz3B1mI2YPtWL5TlnkxGkEu
NSString * const kBdpLeastVersion = @"leastVersion";
// 启动后进行relaunch 和 path配套使用
NSString * const kBdpRelaunch = @"relaunch";
NSString * const kBdpRelaunchPath = @"path";
// 半屏参数
NSString * const kBdpXScreenMode = @"mode";
NSString * const kBdpXScreenStyle = @"panel_style";
NSString * const kBdpXScreenChatID = @"chat_id";


NSString * const kToken = @"token"; // preview 相关
NSString * const kVersionId = @"versionid"; // preview 相关
NSString * const kBDPIdeDisableDomainCheck = @"ide_disable_domain_check";  // web-view安全域名调试

// iPad标签页打开参数
NSString * const kOpenInTemporay = @"showTemporary";

// 保活启动参数,仅用于保活透传启动参数
NSString * const kLauncherFrom = @"launcher_from";

@interface SSLocalModel ()
@property (nonatomic, copy, readwrite) NSString *leastVersion;
@end

@implementation SSLocalModel

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {

        if ([url.host isEqualToString:kHostMicroApp]) {
            if (BDPIsEmptyString(url.path)) {
                _type = SSLocalTypeOpen;
            }
        } else if ([url.host isEqualToString:kHostMiniProgram]) {
            if ([url.path isEqualToString:kPathDpdtLog]) {
                _type = SSLocalTypeLog;
            }
        }

        NSDictionary *query = [url ema_queryItems];
        _app_id = [query bdp_stringValueForKey:kAppId];
        _isdev = [query bdp_intValueForKey:kIsDev];
        _start_page = [query bdp_stringValueForKey:kStartPage];
        if (_start_page) {
            NSURL *startPageUrl = [NSURL URLWithString:_start_page];
            if (startPageUrl) {
                _start_page_no_query = startPageUrl.path;
            } else {
                _start_page_no_query = _start_page;
            }
        }
        _refererInfo = [query bdp_stringValueForKey:kRefererInfo];
        _useCache = [query bdp_stringValueForKey:kUseCache];
        _bdp_launch_query = [query bdp_stringValueForKey:kBdpLaunchQueryKey];
        _required_launch_ability = [query bdp_stringValueForKey:kBdpLaunchRequestAbilityKey];
        _scene = [query bdp_intValueForKey:kScene];
        _versionType = OPAppVersionTypeFromString([query bdp_stringValueForKey:kVersionType]);
        _ws_for_debug = [query bdp_stringValueForKey:kBDPSchemaKeyWSForDebug];
        _leastVersion = [query bdp_stringValueForKey:kBdpLeastVersion];
        _ideDisableDomainCheck = [query bdp_stringValueForKey:kBDPIdeDisableDomainCheck];
        _XScreenMode = [query bdp_stringValueForKey:kBdpXScreenMode];
        _XScreenStyle = [query bdp_stringValueForKey:kBdpXScreenStyle];
        _chatID = [query bdp_stringValueForKey:kBdpXScreenChatID];
    }
    return self;
}

-(void)updateLeastVersionIfExisted:(NSDictionary *)params
{
    _leastVersion = [params bdp_stringValueForKey:kBdpLeastVersion] ?: _leastVersion;
}

- (NSURL * _Nullable)generateURL {
    NSURLComponents *url = [[NSURLComponents alloc] initWithString:@"sslocal://"];
    if (self.type == SSLocalTypeOpen) {
        url.host = kHostMicroApp;
    }else if (self.type == SSLocalTypeLog) {
        url.host = kHostMiniProgram;
        url.path = kPathDpdtLog;
    }
    [url setQueryItemWithKey:kAppId value:self.app_id];
    if (self.isdev) {
        [url setQueryItemWithKey:kIsDev value:@(self.isdev).stringValue];
    }
    [url setQueryItemWithKey:kStartPage value:self.start_page];
    [url setQueryItemWithKey:kRefererInfo value:self.refererInfo];
    [url setQueryItemWithKey:kBdpLaunchQueryKey value:self.bdp_launch_query];
    [url setQueryItemWithKey:kBdpLaunchRequestAbilityKey value:self.required_launch_ability];
    [url setQueryItemWithKey:kScene value:@(self.scene).stringValue];
    [url setQueryItemWithKey:kUseCache value:self.useCache];
    [url setQueryItemWithKey:kVersionType value:OPAppVersionTypeToString(self.versionType)];
    [url setQueryItemWithKey:kBDPSchemaKeyWSForDebug value:self.ws_for_debug];
    [url setQueryItemWithKey:kBdpLeastVersion value:self.leastVersion];
    [url setQueryItemWithKey:kBdpRelaunch value:self.relaunch];
    [url setQueryItemWithKey:kBdpRelaunchPath value:self.relaunchPath];
    [url setQueryItemWithKey:kBDPIdeDisableDomainCheck value:self.ideDisableDomainCheck];
    [url setQueryItemWithKey:kBdpXScreenMode value:self.XScreenMode];
    [url setQueryItemWithKey:kBdpXScreenStyle value:self.XScreenStyle];
    [url setQueryItemWithKey:kBdpXScreenChatID value:self.chatID];

    if(self.versionId) {
        [url setQueryItemWithKey:kVersionId value:self.versionId];
    }
    if(self.token) {
        [url setQueryItemWithKey:kToken value:self.token];
    }

    return url.URL;
}

- (BDPUniqueID *)uniqueID {
    // sslocal 目前只支持小程序形态，所以使用 BDPTypeNativeApp
    return [BDPUniqueID uniqueIDWithAppID:self.app_id identifier:nil versionType:self.versionType appType:BDPTypeNativeApp];
}

@end

