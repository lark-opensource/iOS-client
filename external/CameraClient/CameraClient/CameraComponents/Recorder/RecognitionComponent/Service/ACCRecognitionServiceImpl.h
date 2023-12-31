//
//  ACCRecognitionServiceImpl.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/6.
//

#import <Foundation/Foundation.h>
#import "ACCRecognitionService.h"


NS_ASSUME_NONNULL_BEGIN

@interface ACCRecognitionServiceImpl : NSObject <ACCRecognitionService>
- (instancetype) initWithInputData:(ACCRecordViewControllerInputData *)inputData;
@end

NS_ASSUME_NONNULL_END
