//
//  BDCTCorePiperHandler+VideoRecord.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/25.
//

#import "BDCTCorePiperHandler+VideoRecord.h"
#import "BDCTVideoRecordViewController.h"
#import "BytedCertManager+VideoRecord.h"
#import "BDCTFlowContext.h"
#import <BDModel/BDModel.h>
#import <BDModel/BDMappingStrategy.h>


@implementation BDCTCorePiperHandler (VideoRecord)

- (void)registerOpenVideoRecord {
    [self registeJSBWithName:@"bytedcert.openVideoRecord" handler:^(NSDictionary *_Nullable piperParams, TTBridgeCallback _Nonnull callback, id<TTBridgeEngine> _Nonnull engine, UIViewController *_Nullable controller) {
        NSMutableDictionary *mutableParams = [NSMutableDictionary dictionary];
        [piperParams enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
            if ([obj isKindOfClass:NSDictionary.class]) {
                [mutableParams addEntriesFromDictionary:obj];
            } else {
                mutableParams[key] = obj;
            }
        }];

        BytedCertVideoRecordParameter *parameter = [[BytedCertVideoRecordParameter alloc] initWithBaseParams:[self.flow.context.parameter bd_modelToJSONObject] identityParams:mutableParams.copy];
        parameter.faceEnvBase64 = self.flow.context.faceEnvImageBase64;
        [BytedCertManager recordVideoWithParameter:parameter fromViewController:controller completion:^(BytedCertError *_Nonnull error) {
            callback(TTBridgeMsgSuccess, [BDCTCorePiperHandler jsbCallbackResultWithParams:nil error:error], nil);
        }];
    }];
}

@end
