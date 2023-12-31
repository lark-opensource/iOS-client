//
//  ACCRecordFrameSamplingHandlerProvider.h
//  CameraClient
//
//  Created by limeng on 2020/5/11.
//

#import <Foundation/Foundation.h>
#import "ACCRecordFrameSamplingServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordFrameSamplingHandlerChain : NSObject

+  (NSArray<ACCRecordFrameSamplingHandlerProtocol> *)loadHandlerChain;

@end

NS_ASSUME_NONNULL_END
