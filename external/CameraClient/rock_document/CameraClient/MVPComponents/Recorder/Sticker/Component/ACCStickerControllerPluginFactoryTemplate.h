//
//  ACCStickerControllerPluginFactoryTemplate.h
//  CameraClient
//
//  Created by Fengfanhua.byte on 2021/11/17.
//

#import <Foundation/Foundation.h>
#import <CameraClient/AWEStickerPickerControllerPluginProtocol.h>

@class ACCPropPickerComponent;
@protocol AWEStickerPickerControllerPluginProtocol;

@protocol ACCStickerControllerPluginFactory <NSObject>

+ (id<AWEStickerPickerControllerPluginProtocol>)pluginWithCompoent:(ACCPropPickerComponent *)component;

@end

@protocol ACCStickerControllerPluginFactoryTemplate <NSObject>

@property (nonatomic, weak, nullable) ACCPropPickerComponent *component;

- (nullable NSArray<Class<ACCStickerControllerPluginFactory>> *)pluginFactoryClasses;

@end

