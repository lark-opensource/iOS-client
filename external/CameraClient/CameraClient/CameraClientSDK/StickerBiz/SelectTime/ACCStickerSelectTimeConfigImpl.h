//
//  ACCStickerSelectTimeConfigImpl.h
//  CameraClient-Pods-Aweme
//
//  Created by guochenxiang on 2020/8/25.
//

#import <Foundation/Foundation.h>
#import "ACCStickerSelectTimeConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@interface ACCStickerSelectTimeConfigImpl : NSObject <ACCStickerSelectTimeConfig>

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;

@end

NS_ASSUME_NONNULL_END
