//
// BDXBridgeCertOpenByteCertMethod+BDXBridgeIMP.h
//

#import "BDXBridgeCertOpenByteCertMethod.h"
#import <byted_cert/BytedCert.h>
#import <ByteDanceKit/ByteDanceKit.h>

bdx_bridge_register_external_global_method(BDXBridgeCertOpenByteCertMethod);


@implementation BDXBridgeCertOpenByteCertMethod (BDXBridgeIMP)

- (void)callWithParamModel:(BDXBridgeCertOpenByteCertMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler {
    NSMutableDictionary *baseParams = [NSMutableDictionary dictionary];
    baseParams[@"scene"] = paramModel.scene;
    baseParams[@"flow"] = paramModel.flow;
    baseParams[@"ticket"] = paramModel.ticket;
    baseParams[@"certAppId"] = paramModel.certAppId;
    baseParams[@"extraParams"] = paramModel.extraParams;
    baseParams[@"h5QueryParams"] = paramModel.h5QueryParams;

    NSMutableDictionary *identityParams = [NSMutableDictionary dictionary];
    identityParams[@"identityName"] = paramModel.identityName;
    identityParams[@"identityCode"] = paramModel.identityCode;

    BytedCertParameter *parameter = [[BytedCertParameter alloc] initWithBaseParams:baseParams.copy identityParams:identityParams.copy];
    [BytedCertManager beginCertificationForResultWithParameter:parameter
                                          faceVerificationOnly:paramModel.faceOnly.boolValue
                                            fromViewController:[BTDResponder topViewController]
                                                  forcePresent:YES
                                                    completion:^(BytedCertResult *_Nullable result) {
                                                        BDXBridgeCertOpenByteCertMethodResultModel *resultModel = [[BDXBridgeCertOpenByteCertMethodResultModel alloc] init];
                                                        resultModel.errorCode = @(result.error.code);
                                                        resultModel.errorMsg = result.error.localizedDescription;
                                                        resultModel.ticket = result.ticket;
                                                        resultModel.certStatus = result.certStatus;
                                                        resultModel.manualStatus = result.manualStatus;
                                                        resultModel.ageRange = @(result.ageRange);
                                                        resultModel.extData = result.extraParams;
                                                        bdx_invoke_block(completionHandler, resultModel, [BDXBridgeStatus statusWithStatusCode:(!result.error.code ? BDXBridgeStatusCodeSucceeded : BDXBridgeStatusCodeFailed)]);
                                                    }];
}

@end
