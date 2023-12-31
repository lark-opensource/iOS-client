//
//  ACCGamePlayNetServiceImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/8/17.
//

#import "ACCGamePlayNetServiceImpl.h"
#import <CreationKitInfra/ACCI18NConfigProtocol.h>
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <TTNetworkManager/TTNetworkManager.h>

@implementation ACCGamePlayNetServiceImpl

- (nonnull NSString *)currentLanguage {
    return ACCI18NConfig().currentLanguage;
}

- (nonnull NSString *)defaultDomain {
    return ACCNetService().defaultDomain;
}

- (nonnull id)uploadWithModel:(nonnull GPRequestModelBlock)requestModelBlock progress:(NSProgress * _Nullable __autoreleasing * _Nullable)progress completion:(GPNetServiceCompletionBlock _Nullable)block {
    GPRequestModel *gpRequestModel = [[GPRequestModel alloc] init];
    requestModelBlock(gpRequestModel);
    return [ACCNetService() uploadWithModel:^(ACCRequestModel * _Nullable requestModel) {
        requestModel.urlString = gpRequestModel.urlString;
        requestModel.params = gpRequestModel.params;
        requestModel.needCommonParams = gpRequestModel.needCommonParams;
        requestModel.headerField = gpRequestModel.headerField;
        requestModel.timeout = gpRequestModel.timeout;
        requestModel.objectClass = gpRequestModel.objectClass;
        GPMutipartFormData *gpFormData = gpRequestModel.formData;
        requestModel.bodyBlock = ^(id<TTMultipartFormData> formData) {
            [formData appendPartWithFileData:gpFormData.data name:gpFormData.name fileName:gpFormData.fileName mimeType:gpFormData.mimeType];
        };
    } progress:progress completion:^(id  _Nullable model, NSError * _Nullable error) {
        if (block) {
            block(model, error);
        }
    }];
}


@end
