//
//  ACCRecordCompleteTrackSender.h
//  CameraClient
//
//  Created by haoyipeng on 2022/2/17.
//

#import <Foundation/Foundation.h>
#import "ACCRecordCompleteTrackSenderProtocol.h"

@class RACSignal;

@interface ACCRecordCompleteTrackSender : NSObject <ACCRecordCompleteTrackSenderProtocol>

- (void)sendCompleteButtonClickedSignal;

@end
