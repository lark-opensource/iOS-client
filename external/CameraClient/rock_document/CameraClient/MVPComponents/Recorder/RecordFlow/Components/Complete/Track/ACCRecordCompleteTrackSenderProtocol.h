//
//  ACCRecordCompleteTrackSenderProtocol.h
//  CameraClient
//
//  Created by haoyipeng on 2022/2/17.
//

#import <Foundation/Foundation.h>

@class RACSignal;
@protocol ACCRecordCompleteTrackSenderProtocol <NSObject>

@property (nonatomic, strong, readonly, nonnull) RACSignal *completeButtonDidClickedSignal;

@end
