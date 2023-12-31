//
//  ACCCameraFactoryImpls.h
//  Pods
//
//  Created by liyingpeng on 2020/7/6.
//

#import <Foundation/Foundation.h>
#import "ACCCameraFactory.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCRecordViewControllerInputData;

@interface ACCCameraFactoryImpls : NSObject <ACCCameraFactory>

- (instancetype)initWithInputData:(ACCRecordViewControllerInputData *)inputData;

@end

NS_ASSUME_NONNULL_END
