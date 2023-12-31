//
//  ACCPropComponentGrayAbilityPlugin+Private.h
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/7/23.
//

#import <TTVideoEditor/IESMMEffectMessage.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCPropComponentGrayAbilityPlugin ()
@property (nonatomic, assign) BOOL hasShownAlertView;
- (BOOL)shouldTransferGrayAbilityMessage:(IESMMEffectMessage *)message;
- (NSDictionary *)p_getJsonFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
