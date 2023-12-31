//
//  AWEModulConfigProtocol.h
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/22.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCModuleConfigProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWEModulConfigProtocol <ACCModuleConfigProtocol>

- (BOOL)shouldEffectSetPoiParameters;

@end

NS_ASSUME_NONNULL_END
