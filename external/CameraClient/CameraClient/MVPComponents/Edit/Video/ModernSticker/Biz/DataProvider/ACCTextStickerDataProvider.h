//
//  ACCTextStickerDataProvider.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/7/1.
//

#import "ACCBaseStickerDataProvider.h"
#import <IESInject/IESInject.h>

@interface ACCTextStickerDataProvider : ACCBaseStickerDataProvider <ACCTextStickerDataProvider>

@property (nonatomic, nullable, weak) id<IESServiceProvider> serviceProvider;

@end
