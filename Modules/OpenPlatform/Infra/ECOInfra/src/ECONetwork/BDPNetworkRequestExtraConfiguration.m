//
//  BDPNetworkConfiguration.m
//  Timor
//
//  Created by 李靖宇 on 2019/11/17.
//

#import "BDPNetworkRequestExtraConfiguration.h"
#import "BDPHTTPRequestSerializer.h"

@implementation BDPNetworkRequestExtraConfiguration

NSString *const kBDPRequestExtraConfigFlagsKey = @"kBDPRequestExtraConfigFlagsKey";

NSString *const kBDPRequestExtraConfigRequestSerializerClassKey = @"kBDPRequestExtraConfigRequestSerializerClassKey";
NSString *const kBDPRequestMethodStrKey = @"kBDPRequestMethodStrKey";
NSString *const kBDPRequestMethodKey = @"kBDPRequestMethodKey";
NSString *const kBDPRequestTypeKey = @"kBDPRequestTypeKey";
NSString *const kBDPRequestHeaderFieldKey = @"kBDPRequestHeaderFieldKey";
NSString *const kBDPRequestProgressAddressKey = @"kBDPRequestProgressAddressKey";
NSString *const kBDPRequestConstructingBodyBlockKey = @"kBDPRequestConstructingBodyBlockKey";
NSString *const kBDPRequestDownloadHeaderCallbackKey = @"kBDPRequestHeaderCallbackKey";
NSString *const kBDPRequestDownloadDataCallbackKey = @"kBDPRequestDataCallbackKey";
NSString *const kBDPRequestTimeoutKey = @"kBDPRequestTimeoutKey";
NSString *const kBDPRequestDownloadDestinationURLKey = @"kBDPRequestDownloadDestinationURLKey";
NSString *const kBDPRequestDownloadOffsetKey = @"kBDPRequestDownloadOffsetKey";
NSString *const kBDPRequestDownloadRequestedLengthKey = @"kBDPRequestDownloadRequestedLengthKey";

+ (BDPNetworkRequestExtraConfiguration*)defaultConfig
{
    BDPNetworkRequestExtraConfiguration * config = [[BDPNetworkRequestExtraConfiguration alloc]init];
    config.method = BDPRequestMethodGET;
    config.type = BDPRequestTypeRequestForJson;
    config.flags = BDPRequestFlagsDefault;
    return config;
}

+ (BDPNetworkRequestExtraConfiguration*)defaultConfigWithHttpMethod:(BDPRequestMethod)method
{
    BDPNetworkRequestExtraConfiguration * config = [BDPNetworkRequestExtraConfiguration defaultConfig];
    config.method = method;
    return config;
}

+ (BDPNetworkRequestExtraConfiguration*)defaultBDPSerializerConfig
{
    BDPNetworkRequestExtraConfiguration * config = [BDPNetworkRequestExtraConfiguration defaultConfig];
    config.bdpRequestSerializerClass = [BDPHTTPRequestSerializer class];
    return config;
}

+ (BDPNetworkRequestExtraConfiguration*)defaultBDPSerializerConfigWithHttpMethod:(BDPRequestMethod)method
{
    BDPNetworkRequestExtraConfiguration * config = [BDPNetworkRequestExtraConfiguration defaultConfigWithHttpMethod:method];
    config.bdpRequestSerializerClass = [BDPHTTPRequestSerializer class];
    return config;
}

@end
