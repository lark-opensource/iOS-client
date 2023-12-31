//
//  ACCPOIStickerDataProvider.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/7/12.
//

#import "ACCBaseStickerDataProvider.h"
#import <IESInject/IESInject.h>

@class AWEVideoPublishViewModel;

@interface ACCPOIStickerDataProvider : ACCBaseStickerDataProvider <ACCPOIStickerDataProvider>

@property (nonatomic, weak, nullable) id<IESServiceProvider> serviceProvider;

@end
