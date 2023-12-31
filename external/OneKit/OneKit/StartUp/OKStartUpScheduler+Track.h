//
//  OKStartUpScheduler+Track.h
//  OneKit
//
//  Created by bob on 2021/1/12.
//

#import "OKStartUpScheduler.h"

NS_ASSUME_NONNULL_BEGIN

@interface OKStartUpScheduler (Track)

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *taskTimeStamps;

- (void)trackStartupTask:(NSString *)taskIdentifier duration:(long long)duration;
- (void)startReport;

@end

NS_ASSUME_NONNULL_END
