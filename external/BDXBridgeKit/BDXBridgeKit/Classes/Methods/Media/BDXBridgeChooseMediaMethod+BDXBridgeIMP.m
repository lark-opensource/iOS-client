//
//  BDXBridgeChooseMediaMethod+BDXBridgeIMP.m
//  BDXBridgeKit-Pods-Aweme
//
//  Created by li keliang on 2021/3/25.
//

#import "BDXBridgeChooseMediaMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import "BDXBridgeServiceManager.h"
#import "BDXBridgeDefaultMediaPicker.h"
#import <objc/runtime.h>
#import <ByteDanceKit/ByteDanceKit.h>

@implementation BDXBridgeChooseMediaMethod (BDXBridgeIMP)
bdx_bridge_register_default_global_method(BDXBridgeChooseMediaMethod);

- (void)callWithParamModel:(BDXBridgeChooseMediaMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    id <BDXBridgeChooseMediaPicker> mediaPicker = nil;
    id<BDXBridgeMediaServiceProtocol> mediaService = bdx_get_service(BDXBridgeMediaServiceProtocol);
    if ([mediaService respondsToSelector:@selector(mediaPicker)]) {
        mediaPicker = [mediaService mediaPicker];
    }
    
    BOOL supported = [mediaPicker supportedWithParamModel:paramModel];
    if (!supported) {
        mediaPicker = self.defaultMediaPicker;
    }
    
    if ([mediaPicker supportedWithParamModel:paramModel]) {
        UIViewController *pickerViewController = [mediaPicker mediaPickerWithParamModel:paramModel completionHandler:^(BDXBridgeChooseMediaMethodResultModel * _Nullable resultModel, BDXBridgeStatus * _Nullable status) {
            bdx_invoke_block(completionHandler, resultModel, status);
        }];
        if (pickerViewController) {
            [[BTDResponder topViewController] presentViewController:pickerViewController animated:YES completion:nil];
            return;
        } else if ([mediaPicker respondsToSelector:@selector(isPresenting)]
                   && [mediaPicker isPresenting]) {
            return;
        }
    }
    
    bdx_invoke_block(completionHandler, nil, [BDXBridgeStatus statusWithStatusCode:BDXBridgeStatusCodeInvalidResult message:@"Not found valid media picker."]);
}

- (BDXBridgeDefaultMediaPicker *)defaultMediaPicker
{
    id defaultMediaPicker = objc_getAssociatedObject(self, _cmd);
    if (!defaultMediaPicker) {
        defaultMediaPicker = [BDXBridgeDefaultMediaPicker new];
        objc_setAssociatedObject(self, _cmd, defaultMediaPicker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return defaultMediaPicker;
}

@end
