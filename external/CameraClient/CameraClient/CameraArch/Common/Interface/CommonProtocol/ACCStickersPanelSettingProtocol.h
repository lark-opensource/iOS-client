//
//  ACCStickersPanelSettingProtocol.h
//  AAWELaunchOptimization-Pods-DouYin
//
//  Created by liujinze on 2020/7/31.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitInfra/AWEModernStickerDefine.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickersPanelSettingProtocol <NSObject>

- (NSString *)transferStickersPanelWithType:(AWEStickerPanelType)type;

@end

FOUNDATION_STATIC_INLINE id<ACCStickersPanelSettingProtocol> ACCPanelSettings() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCStickersPanelSettingProtocol)];
}

NS_ASSUME_NONNULL_END





