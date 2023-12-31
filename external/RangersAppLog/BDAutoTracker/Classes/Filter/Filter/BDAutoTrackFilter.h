//
//  BDAutoTrackFilter.h
//  RangersAppLog
//
//  Created by bob on 2020/6/11.
//

#import "BDAutoTrackService.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackFilter : BDAutoTrackService<BDAutoTrackFilterService>

- (instancetype)initWithAppID:(NSString *)appID;

- (void)loadBlockList;
- (void)updateBlockList:(NSDictionary *)eventList save:(BOOL)save;
- (void)clearBlockList;

- (nullable NSDictionary *)filterEvent:(NSDictionary *)event;

@end

NS_ASSUME_NONNULL_END
