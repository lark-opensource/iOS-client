//
//  BDAutoTrackActivateRequest.h
//  RangersAppLog
//
//  Created by bob on 2019/9/15.
//

#import "BDAutoTrackRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackActivateRequest : BDAutoTrackRequest

@property (atomic, assign) BOOL needActiveUser;

@end

NS_ASSUME_NONNULL_END
