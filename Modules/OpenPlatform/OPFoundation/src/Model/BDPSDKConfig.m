//
//  BDPSDKConfig.m
//  Timor
//
//  Created by muhuai on 2018/5/9.
//

#import "BDPSDKConfig.h"
#import "BDPUtils.h"
#import <OPFoundation/OPFoundation-Swift.h>

@implementation BDPSDKConfig

+ (instancetype)sharedConfig {
    static BDPSDKConfig *config;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [[BDPSDKConfig alloc] init];
    });
    
    return config;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _disableServiceURL = @"https://developer.toutiao.com/systemdown";
        _disableAppURL = @"https://developer.toutiao.com/appdown";
        _unsupportedContextURL = @"https://developer.toutiao.com/unsupported";
        _unsupportediOSSystem = @"https://developer.toutiao.com/unsupported?type=ios_unsupported";
        _unsupportedOSVersion = @"https://developer.toutiao.com/unsupported?type=os_unsupported";
        _unsupportedDeviceModel = @"https://developer.toutiao.com/unsupported?type=model_unsupported";
        _unsupportedLandscapeURL = @"https://developer.toutiao.com/unsupported?type=orientation_landscape_unsupported";
        _unsupportedPortraitURL = @"https://developer.toutiao.com/unsupported?type=orientation_portrait_unsupported";
        _unsupportedUnconfigSchemaURL = @"https://developer.toutiao.com/unsupported?unconfig_schema=";
        _unsupportedUnconfigDomainURL = @"https://developer.toutiao.com/unsupported?unconfig_domain=";
        _userLoginURL = @"https://developer.toutiao.com/api/apps/v2/login";
        _userInfoURL = @"https://developer.toutiao.com/api/apps/v2/user/info";
        _rankDataURL = @"https://developer.toutiao.com/api/apps/rank";
        _appMetaURL = @"https://developer.toutiao.com/api/apps/v3/meta";
        _aboutURL = @"https://developer.toutiao.com/api/apps/about";
        _decodeShareTokenURL = @"https://developer.toutiao.com/api/apps/share/decode_token";
        _shareImgUploadURL = @"https://developer.toutiao.com/api/apps/share/upload_image";
        _shareDefaultMsgURL = @"https://developer.toutiao.com/api/apps/share/default_share_info";
        _shareMsgURL = @"https://developer.toutiao.com/api/apps/share/share_message";
        _deleteShareDataURL = @"https://developer.toutiao.com/api/apps/share/delete_share_token";
        _setUserGroupURL = @"https://developer.toutiao.com/api/apps/user/group";
        _authorizationSetURL = @"https://developer.toutiao.com/api/apps/authorization/set";
        _getUsageRecordURL = @"https://developer.toutiao.com/api/apps/history";
        _removeUsageRecordURL = @"https://developer.toutiao.com/api/apps/history/remove";
        _usageRecordURL = @"https://developer.toutiao.com/api/apps/history/add";
        _getPhoneNumberURL = @"https://developer.toutiao.com/api/apps/user/phonenumber";
        _logReportURL = @"https://developer.toutiao.com/api/apps/report";
        _getShareInfoUrl = @"https://developer.toutiao.com/api/apps/share/query_open_gid";
        _followStateURL = @"https://developer.toutiao.com/api/apps/follow/state";
        _followMediaGetURL = @"https://developer.toutiao.com/api/apps/follow/media/get";
        _followMediaFollowURL = @"https://developer.toutiao.com/api/apps/follow/media/follow";
        _defaultWebViewHostWhiteList = @[
                                         @"developer.toutiao.com"
                                         ];
        _onlineTimeReportedURL = @"https://gms-api.bytedance.com/health/v2/update_time";
        _identityAuthenticationURL = @"https://gms-api.bytedance.com/health/v2/update_identity_info";
        _customerServiceURL = @"https://developer.toutiao.com/api/apps/im/url/generate";
        _serviceRefererURL = @"https://tmaservice.developer.toutiao.com";
        _locationURL = @"https://developer.toutiao.com/api/apps/location/user";
        _openDataBaseURL = @"https://developer.toutiao.com/api/apps";
        _jssdkEnvConfig = @{};
        _appMetaPubKey = @"-----BEGIN PUBLIC KEY-----"
        @"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDTb2DxxIj17sf2H/hr6ZSNxsaa"
        @"FjgCMHZOSZsvAaZpl+9hHd76ex1nVCpZXbjIsYHfJzYLVDlRZYXcHA3yOhneyJbC"
        @"kO4e05t+5j/lXWQY09gkp9w3pGIWOCzfr8zY/5CA3ThIbNBKFQZTnX8nQIhaTf+u"
        @"nJDe6Nkq3Tau6cz75QIDAQAB"
        @"-----END PUBLIC KEY-----";
        _jssdkVersion = @"";
        _jssdkDownloadURL = @"";
        _jssdkGreyHash = @"";
        _debugRuntimeType = OPRuntimeTypeUnknown;
        _appLaunchInfoDeleteOldDataDays = @"180";
    }
    return self;
}
@end
