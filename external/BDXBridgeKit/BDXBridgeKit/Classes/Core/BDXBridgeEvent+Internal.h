//
//  BDXBridgeEvent+Internal.h
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/9/6.
//

#import "BDXBridgeEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXBridgeEvent (Internal)

@property (nonatomic, assign, readonly) NSTimeInterval bdx_timestamp;

- (void)bdx_updateTimestampWithCurrentDate;
- (void)bdx_updateTimestampWithMillisecondTimestamp:(NSTimeInterval)timestamp;

@end

NS_ASSUME_NONNULL_END
