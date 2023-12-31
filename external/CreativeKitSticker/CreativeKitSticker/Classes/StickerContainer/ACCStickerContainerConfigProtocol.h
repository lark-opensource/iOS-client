//
//  ACCStickerContainerConfigProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/10/7.
//

#import "ACCStickerPluginProtocol.h"
#import "ACCStickerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStickerContainerConfigProtocol <NSCopying>

@property (nonatomic, strong, nullable) id contextId;

@property (nonatomic, copy) NSComparator stickerHierarchyComparator;

@property (nonatomic, assign) BOOL ignoreMaskRadiusForXScreen;

- (Class<ACCStickerProtocol>)stickerFactoryClass;

- (Class<ACCStickerPluginProtocol>)stickerPluginConfigClass;

- (NSArray<id<ACCStickerContainerPluginProtocol>> *)stickerPlugins;

@end

NS_ASSUME_NONNULL_END
