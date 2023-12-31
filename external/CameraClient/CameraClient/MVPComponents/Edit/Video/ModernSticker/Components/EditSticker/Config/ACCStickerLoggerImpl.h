//
//  ACCStickerLoggerImpl.h
//  Pods
//
//  Created by liyingpeng on 2020/8/5.
//

#import <Foundation/Foundation.h>
#import "ACCStickerLogger.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@interface ACCStickerLoggerImpl : NSObject <ACCStickerLogger>

@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;

@end

NS_ASSUME_NONNULL_END
