//
//  MODACCNetServiceImpl.m
//  Modeo
//
//  Created by yansong li on 2020/12/24.
//

#import "MODACCNetServiceImpl.h"

#import "MODMacros.h"
#import "MODNetworkService.h"
#import <AWEBaseLib/AWEMacros.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "LarkVideoDirector/LarkVideoDirector-Swift.h"

@implementation MODACCNetServiceImpl

- (NSDictionary *)commonParameters
{
    return [MODACCNetServiceImpl buildCommonParams];
}

- (NSString *)defaultDomain
{
    return AWEME_DOMAIN;
}

- (NSError *)invalidParameterError
{
    return nil;
}

#pragma mark - get/post

- (id)GET:(NSString *)urlString
    params:(NSDictionary *_Nullable)params
modelClass:(Class _Nullable)objectClass
completion:(ACCNetServiceCompletionBlock _Nullable)block
{
    NSAssert(urlString, @"urlString should not be empty");
    
    if (objectClass) {
        return [MODNetworkService getWithURLString:urlString params:params modelClass:objectClass completion:^(id  _Nullable model, NSError * _Nullable error) {
            MODBLOCK_INVOKE(block,model,error);
        }];
    } else {
        return [MODNetworkService getWithURLString:urlString params:params completion:^(id  _Nullable model, NSError * _Nullable error) {
            MODBLOCK_INVOKE(block,model,error);
        }];
    }
}

- (id)POST:(NSString *)urlString
    params:(NSDictionary *_Nullable)params
modelClass:(Class _Nullable)objectClass
completion:(ACCNetServiceCompletionBlock _Nullable)block
{
    NSAssert(urlString, @"urlString should not be empty");
    
    if (objectClass) {
        return [MODNetworkService postWithURLString:urlString params:params modelClass:objectClass completion:^(id  _Nullable model, NSError * _Nullable error) {
            MODBLOCK_INVOKE(block,model,error);
        }];
    } else {
        return [MODNetworkService postWithURLString:urlString params:params completion:^(id  _Nullable model, NSError * _Nullable error) {
            MODBLOCK_INVOKE(block,model,error);
        }];
    }
}

- (id)requestWithModel:(ACCRequestModelBlock)requestModelBlock completion:(ACCNetServiceCompletionBlock _Nullable)block
{
    ACCRequestModel *requestModel = [[ACCRequestModel alloc] init];
    MODBLOCK_INVOKE(requestModelBlock,requestModel);
    NSAssert(requestModel.urlString, @"urlString should not be empty");
    
    TTHttpTask *request = nil;
    
    if (requestModel.requestType == ACCRequestTypeGET) {
        if (requestModel.objectClass) {
            if (requestModel.timeout > 0) {
                request = [MODNetworkService requestWithURLString:requestModel.urlString params:requestModel.params method:@"GET" needCommonParams:requestModel.needCommonParams modelClass:requestModel.objectClass targetAttributes:nil timeout:requestModel.timeout responseSerializer:nil responseBlock:nil completionBlock:^(id  _Nullable model, NSError * _Nullable error) {
                    MODBLOCK_INVOKE(block,model,error);
                }];
            } else {
                request = [MODNetworkService getWithURLString:requestModel.urlString params:requestModel.params modelClass:requestModel.objectClass completion:^(id  _Nullable model, NSError * _Nullable error) {
                    MODBLOCK_INVOKE(block,model,error);
                }];
            }
        } else {
            if (requestModel.timeout > 0) {
                request = [MODNetworkService requestWithURLString:requestModel.urlString params:requestModel.params method:@"GET" needCommonParams:requestModel.needCommonParams modelClass:nil targetAttributes:nil timeout:requestModel.timeout responseSerializer:nil responseBlock:nil completionBlock:^(id  _Nullable model, NSError * _Nullable error) {
                    MODBLOCK_INVOKE(block,model,error);
                }];
            } else {
                request = [MODNetworkService getWithURLString:requestModel.urlString params:requestModel.params completion:^(id  _Nullable model, NSError * _Nullable error) {
                    MODBLOCK_INVOKE(block,model,error);
                }];
            }
        }
    } else if (requestModel.requestType == ACCRequestTypePOST) {
        if (requestModel.objectClass) {
            if (requestModel.timeout > 0) {
                request = [MODNetworkService requestWithURLString:requestModel.urlString params:requestModel.params method:@"POST" needCommonParams:requestModel.needCommonParams modelClass:requestModel.objectClass targetAttributes:nil timeout:requestModel.timeout responseSerializer:nil responseBlock:nil completionBlock:^(id  _Nullable model, NSError * _Nullable error) {
                    MODBLOCK_INVOKE(block,model,error);
                }];
            } else {
                request = [MODNetworkService postWithURLString:requestModel.urlString params:requestModel.params modelClass:requestModel.objectClass completion:^(id  _Nullable model, NSError * _Nullable error) {
                    MODBLOCK_INVOKE(block,model,error);
                }];
            }
        } else {
            if (requestModel.timeout) {
                request = [MODNetworkService requestWithURLString:requestModel.urlString params:requestModel.params method:@"POST" needCommonParams:requestModel.needCommonParams modelClass:nil targetAttributes:nil timeout:requestModel.timeout responseSerializer:nil responseBlock:nil completionBlock:^(id  _Nullable model, NSError * _Nullable error) {
                    MODBLOCK_INVOKE(block,model,error);
                }];
            } else {
                request = [MODNetworkService postWithURLString:requestModel.urlString params:requestModel.params completion:^(id  _Nullable model, NSError * _Nullable error) {
                    MODBLOCK_INVOKE(block,model,error);
                }];
            }
        }
    } else {
        //do nothing
    }
    return request;
}

#pragma mark - upload

- (id)uploadWithModel:(ACCRequestModelBlock)requestModelBlock
             progress:(NSProgress *_Nullable __autoreleasing *_Nullable)progress
           completion:(ACCNetServiceCompletionBlock _Nullable)block
{
    return nil;
}

#pragma mark - download

- (void)downloadWithModel:(ACCRequestModelBlock)requestModelBlock
            progressBlock:(ACCNetworkServiceDownloadProgressBlock _Nullable)progressBlock
               completion:(ACCNetworkServiceDownloadComletionBlock)completionBlock
{
}

#pragma mark - cancel
- (void)cancel:(id)request
{
}

+ (NSDictionary *)buildCommonParams
{
    NSMutableDictionary *commonParams = [NSMutableDictionary new];
    [commonParams addEntriesFromDictionary:[self buildConsistentCommonParams]];
    [commonParams addEntriesFromDictionary:[self buildDynamicCommonParams]];
    return [commonParams copy];
}

+ (NSDictionary *)buildConsistentCommonParams {
    static NSDictionary *p_commonParams = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary *commonParams = [NSMutableDictionary dictionary];
        [commonParams setValue: [UIApplication btd_currentChannel] forKey:@"channel"];
        [commonParams setValue:[UIApplication btd_appName] forKey:@"app_name"];
        [commonParams setValue:[LVDCameraConfig appID] forKey:@"aid"];
        [commonParams setValue:[UIApplication btd_versionName] forKey:@"version_code"];
        [commonParams setValue:[UIApplication btd_versionName] forKey:@"app_version"];
        [commonParams setValue:[UIApplication btd_bundleVersion] forKey:@"build_number"];
        [commonParams setValue:[UIApplication btd_platformName] forKey:@"device_platform"];
        [commonParams setValue:[UIDevice btd_OSVersion] forKey:@"os_version"];
        [commonParams setValue:[UIDevice btd_platform] forKey:@"device_type"];
        // screen_width
        CGFloat scale = [UIScreen mainScreen].scale;
        [commonParams setValue:@((int)MIN([UIDevice btd_screenWidth]*scale, [UIDevice btd_screenHeight]*scale)) forKey:@"screen_width"];
        p_commonParams = [commonParams copy];

    });
    return p_commonParams;
}


+ (NSDictionary *)buildDynamicCommonParams {
    NSMutableDictionary *dynamicCommonParams = [NSMutableDictionary new];
    [dynamicCommonParams setValue:[LVDCameraConfig appLanguage] forKey:@"app_language"];
    [dynamicCommonParams setValue:[LVDCameraConfig installID] forKey:@"iid"];
    [dynamicCommonParams setValue:[LVDCameraConfig deviceID] forKey:@"device_id"];

    return [dynamicCommonParams copy];
}

@end
