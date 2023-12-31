//
//  BytedCertManager+OCR.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/11.
//

#import "BytedCertManager+OCR.h"
#import "BDCTImageManager.h"
#import "BDCTAPIService.h"
#import "BDCTLog.h"
#import "BDCTFlowContext.h"
#import "BytedCertManager+Private.h"

#import <objc/runtime.h>


@implementation BytedCertManager (OCR)

- (BDCTImageManager *)imageManager {
    BDCTImageManager *imageManager = objc_getAssociatedObject(self, _cmd);
    if (!imageManager) {
        imageManager = [BDCTImageManager new];
        objc_setAssociatedObject(self, _cmd, imageManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return imageManager;
}

+ (void)takePhotoByCameraWithParams:(NSDictionary *)params completion:(void (^)(NSDictionary *_Nonnull))completion {
    NSMutableDictionary *mutableArgs = [params mutableCopy] ?: [NSMutableDictionary dictionary];
    [mutableArgs setValue:@(YES) forKey:@"is_only_camera"];
    [BytedCertManager.shareInstance.imageManager selectImageWithParams:mutableArgs.copy completion:completion];
}

+ (void)selectImageByAlbumWithParams:(NSDictionary *)params completion:(void (^)(NSDictionary *_Nonnull))completion {
    NSMutableDictionary *mutableArgs = [params mutableCopy] ?: [NSMutableDictionary dictionary];
    [mutableArgs setValue:@(YES) forKey:@"is_only_album"];
    [BytedCertManager.shareInstance.imageManager selectImageWithParams:mutableArgs.copy completion:completion];
}

+ (void)getImageWithParams:(NSDictionary *)params completion:(void (^)(NSDictionary *_Nonnull))completion {
    [BytedCertManager.shareInstance.imageManager selectImageWithParams:params completion:completion];
}

+ (void)doOCRWithImageType:(NSString *)type params:(NSDictionary *)params completion:(void (^)(NSDictionary *_Nullable, BytedCertError *_Nullable))completion {
    BytedCertParameter *parameter = [[BytedCertParameter alloc] initWithBaseParams:params identityParams:nil];
    BDCTFlowContext *context = [BDCTFlowContext contextWithParameter:parameter];
    BDCTFlow *flow = [[BDCTFlow alloc] initWithContext:context];
    [flow.apiService bytedInitWithCallback:^(NSDictionary *_Nullable data, BytedCertError *_Nullable error) {
        if (error) {
            BDCTLogInfo(@"%zd\n", error.errorCode);
            !completion ?: completion(nil, error);
        } else {
            NSData *imageData = [BytedCertManager.shareInstance.imageManager getImageByType:type];
            [flow.apiService bytedCommonOCR:imageData type:type callback:^(NSDictionary *_Nullable data, BytedCertError *_Nullable error) {
                if (error) {
                    BDCTLogInfo(@"%zd\n", error.errorCode);
                    !completion ?: completion(nil, error);
                } else {
                    !completion ?: completion(data, nil);
                }
            }];
        }
    }];
}

@end
