//
//  BDXBridgeVibrateMethod+BDXBridgeIMP.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/16.
//

#import "BDXBridgeVibrateMethod+BDXBridgeIMP.h"
#import "BDXBridge+Internal.h"
#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>

@implementation BDXBridgeVibrateMethod (BDXBridgeIMP)
bdx_bridge_register_internal_global_method(BDXBridgeVibrateMethod);

- (void)callWithParamModel:(BDXBridgeVibrateMethodParamModel *)paramModel completionHandler:(BDXBridgeMethodCompletionHandler)completionHandler
{
    UIImpactFeedbackStyle style = UIImpactFeedbackStyleLight;
    switch (paramModel.style) {
        case BDXBridgeVibrationStyleLight:
            style = UIImpactFeedbackStyleLight;
            break;
        case BDXBridgeVibrationStyleMedium:
            style = UIImpactFeedbackStyleMedium;
            break;
        case BDXBridgeVibrationStyleHeavy:
            style = UIImpactFeedbackStyleHeavy;
            break;
        default:
            break;
    }
    [self vibrateWithStyle:style];
    bdx_invoke_block(completionHandler, nil, nil);
}
 
- (void)vibrateWithStyle:(UIImpactFeedbackStyle) style
{
    if (@available(iOS 10.0 , *)) {
        UIImpactFeedbackGenerator *impact = [[UIImpactFeedbackGenerator alloc] initWithStyle:style];
        [impact impactOccurred];
    } else {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
}

@end
