//
//  ACCFlowerServiceImpl.h
//  CameraClient-Pods-AwemeCore
//
//  Created by bytedance on 2021/11/12.
//

#import <Foundation/Foundation.h>
#import "ACCFlowerService.h"
#import "ACCRecordViewControllerInputData.h"

@interface ACCFlowerServiceImpl : NSObject <ACCFlowerService>

- (instancetype)initWithInputData:(ACCRecordViewControllerInputData *)inputData;

@end
