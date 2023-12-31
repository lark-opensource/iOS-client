//
//  ACCStickerPluginProtocol.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/7.
//

#import <Foundation/Foundation.h>
#import "ACCStickerContainerPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerPluginProtocol <NSObject>

+ (NSArray <__kindof id <ACCStickerContainerPluginProtocol>> *)resortPluginPriority:(NSArray <__kindof id <ACCStickerContainerPluginProtocol>> *)pluginList;

@end

NS_ASSUME_NONNULL_END
