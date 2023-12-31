//
//  ACCStickerPannelLoggerImpl.h
//  Pods
//
//  Created by liyingpeng on 2020/8/4.
//

#import <Foundation/Foundation.h>
#import "ACCStickerPannelLogger.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerPannelLoggerImpl : NSObject <ACCStickerPannelLogger>

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;

@end

NS_ASSUME_NONNULL_END
