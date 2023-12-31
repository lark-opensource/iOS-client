//
//  BDAuoTrackEventBlock.h
//  RangersAppLog
//
//  Created by bytedance on 2022/8/19.
//

@interface BDAuoTrackEventBlock : NSObject

@property (nonatomic, copy) NSString *appID;

- (instancetype)initWithAppID:(NSString *)appID;

- (void)updateBlockList:(NSArray *)blockList;

- (BOOL)hasEvent:(NSString *)event;

@end
