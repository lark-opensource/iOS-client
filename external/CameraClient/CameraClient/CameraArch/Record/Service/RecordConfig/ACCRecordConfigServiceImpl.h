//
//  ACCRecordConfigServiceImpl.h
//  CameraClient
//
//  Created by liuqing on 2020/4/20.
//

#import <Foundation/Foundation.h>
#import "ACCRecordConfigService.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordConfigServiceImpl : NSObject <ACCRecordConfigService>

@property (nonatomic, strong, readonly) AWEVideoPublishViewModel *publishModel;

@end

NS_ASSUME_NONNULL_END
