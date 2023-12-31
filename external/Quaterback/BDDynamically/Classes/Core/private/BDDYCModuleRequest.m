//
//  BDDYCModuleRequest.m
//  BDDynamically
//
//  Created by zuopengliu on 7/3/2018.
//

#import "BDDYCModuleRequest.h"
#import "BDDYCMultipartFormData.h"
#import "BDDYCMacros.h"
#import "BDDYCDevice.h"
#import "BDDYCNSURLHelper.h"
#import "BDDYCModelKey.h"



#define kBDDYCDefaultDomain     (@"security.snssdk.com")

#define kBDDYCDefaultURLPath    (@"api/byte/config/v5")

@implementation BDDYCModuleRequest

@synthesize osVersion           = _osVersion;
@synthesize devicePlatform      = _devicePlatform;
@synthesize deviceHardwareType  = _deviceHardwareType;
@synthesize activeArch          = _activeArch;

- (NSString *)domainName
{
    return (_domainName ? : kBDDYCDefaultDomain);
}

- (NSString *)requestUrl
{
    if (_requestUrl) return _requestUrl;
    NSString *urlString = [NSString stringWithFormat:@"https://%@/%@/?",
                           self.domainName, kBDDYCDefaultURLPath];
    _requestUrl = urlString;
    return _requestUrl;
}

#pragma mark - Getter/Setter

- (NSString *)aid
{
    return _aid ? : [[[NSBundle mainBundle] infoDictionary] objectForKey:@"SSAppID"];
}

- (NSString *)appName
{
    return _appName ? : [[NSBundle mainBundle] bundleIdentifier];
}

- (NSString *)channel
{
    return _channel ? : ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CHANNEL_NAME"] ? : @"App Store");
}

- (NSString *)osVersion
{
    return [[UIDevice currentDevice] systemVersion];
}

- (NSString *)systemName
{
    return [[UIDevice currentDevice] systemName];
}

- (NSString *)devicePlatform
{
    // 设备平台固定写死为 `iphone`
    return  [BDDYCDevice getPlatformString];
}

- (NSString *)deviceHardwareType
{
    if (!_deviceHardwareType) {
        _deviceHardwareType = [BDDYCDevice getMachineHardwareString];
    }
    return _deviceHardwareType;
}

- (NSString *)activeArch
{
    if (!_activeArch) {
        _activeArch = [BDDYCDevice getBCValidARCHString];
    }
    _activeArch = [[BDDYCDevice getiPhoneARCHSMap] objectForKey:_activeArch];
    return _activeArch;
}

- (NSString *)language
{
    NSString *language = [[NSLocale preferredLanguages] firstObject];
    if (language) return language;
    if (@available(iOS 10.0, *)) {
        return [[NSLocale currentLocale] languageCode];
    }
    return nil;
}

- (NSString *)contryCode
{
    if (@available(iOS 10.0, *)) {
        return [[NSLocale currentLocale] countryCode];
    }
    return nil;
}

@end



@implementation BDDYCModuleRequest (NSURLRequest)

+ (NSURLRequest *)requestWithModuleListURL:(NSString *)urlString
                               queryParams:(NSDictionary *)params
                                  formData:(NSDictionary *)formDict
                                  bodyData:(NSDictionary *)bodyDict
{
    BDDYCAssert(urlString && "url must be configuration");
    if (!urlString) return nil;
    
    urlString = BDDYCURLAppendQueryParameters(urlString, params);
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                                  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                              timeoutInterval:20.0];
    mutableRequest.HTTPMethod = @"POST";
    mutableRequest.allowsCellularAccess = YES;
    // BDDYCStreamingMultipartFormData *formData = [[BDDYCStreamingMultipartFormData alloc] initWithURLRequest:mutableRequest stringEncoding:NSUTF8StringEncoding];
    // [formDict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
    //     [formData appendPartWithFormJSONObject:obj name:key];
    // }];
    // [formData requestByFinalizingMultipartFormData];
    [mutableRequest setValue:@"application/json"
          forHTTPHeaderField:@"Content-Type"];
    [mutableRequest setHTTPBody:[NSJSONSerialization dataWithJSONObject:bodyDict options:0 error:NULL]];
    return [mutableRequest copy];
}

- (NSURLRequest *)requestWithFormData:(NSDictionary *)formDict body:(NSDictionary *)bodyDict
{
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:self.queryParams];
    [mutableParams setValue:self.aid
                     forKey:kBDDYCAppIdReqKey];
    [mutableParams setValue:self.appName
                     forKey:kBDDYCAppNameReqKey];
    [mutableParams setValue:self.deviceId
                     forKey:kBDDYCDeviceIdReqKey];
    [mutableParams setValue:self.channel
                     forKey:kBDDYCChannelReqKey];
    [mutableParams setValue:self.osVersion
                     forKey:kBDDYCOSVersionReqKey];
    [mutableParams setValue:self.appVersion
                     forKey:kBDDYCAppVersionReqKey];
    [mutableParams setValue:self.appBuildVersion
                     forKey:kBDDYCAppBuildVersionReqKey];
    [mutableParams setValue:self.devicePlatform
                     forKey:kBDDYCDevicePlatformReqKey];
    [mutableParams setValue:self.deviceHardwareType
                     forKey:kBDDYCDeviceMachineReqKey];
    [mutableParams setValue:self.activeArch
                     forKey:kBDDYCActiveArchReqKey];
    [mutableParams setValue:@(self.engineType)
                     forKey:kBDDYCEngineTypeReqKey];
    
    [mutableParams setValue:[[NSLocale currentLocale] localeIdentifier]
                     forKey:kBDDYCLocaleIdentifierReqKey];
    [mutableParams setValue:self.language
                     forKey:kBDDYCLanguageReqKey];
    [mutableParams setValue:self.contryCode
                     forKey:kBDDYCCountryCodeReqKey];
    [mutableParams setValue:[BDDYCDevice getDeviceModel] forKey:@"device_model"];
    
    NSMutableDictionary *mutableBodyDict = [[NSMutableDictionary alloc] initWithDictionary:bodyDict];

    [mutableBodyDict setValue:(self.quaterbacks ? : [NSArray new])
                       forKey:kBDDYCQuaterbackListReqKey];
    self.bodyParams = mutableBodyDict;

    return [self.class requestWithModuleListURL:self.requestUrl
                                    queryParams:[mutableParams copy]
                                       formData:[formDict copy]
                                       bodyData:[mutableBodyDict copy]];
}

@end

