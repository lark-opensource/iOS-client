//
//  ACCStickerDataProvider.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/7/12.
//

#import <Foundation/Foundation.h>
#import "ACCStickerDataProvider.h"

@class AWEVideoPublishViewModel;

@interface ACCBaseStickerDataProvider : NSObject <ACCStickerDataProvider>

@property (nonatomic, weak, nullable) AWEVideoPublishViewModel *repository;

@end
