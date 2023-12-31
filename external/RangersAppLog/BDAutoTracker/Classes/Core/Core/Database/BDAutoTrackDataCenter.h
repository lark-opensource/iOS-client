//
//  BDAutoTrackDataCenter.h
//  Applog
//
//  Created by bob on 2019/1/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BDAutoTrack;

/// event 加工包装
@interface BDAutoTrackDataCenter : NSObject

@property (nonatomic, assign) BOOL showDebugLog;

- (instancetype)initWithAppID:(NSString *)appID associatedTrack:(BDAutoTrack *)track;

- (void)trackWithTableName:(NSString *)tableName data:(NSDictionary *)data;

- (void)trackUIEventWithData:(NSDictionary *)data;

- (void)trackLaunchEventWithData:(NSMutableDictionary *)data;

- (void)trackTerminateEventWithData:(NSMutableDictionary *)data;

- (void)trackUserEventWithData:(NSDictionary *)data;

- (void)trackProfileEventWithData:(NSDictionary *)data;

- (void)clearDatabase;

- (NSInteger)trackGlobalEventID;

@end

NS_ASSUME_NONNULL_END
