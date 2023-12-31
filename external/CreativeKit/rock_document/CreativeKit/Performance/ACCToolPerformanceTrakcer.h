//
//  ACCToolPerformanceTrakcer.h
//  CreativeKit-Pods-Aweme
//
//  Created by Liyingpeng on 2021/7/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCToolPerformanceTrakcer : NSObject

@property (nonatomic, copy, nullable) NSArray *waitingKeyArray;
@property (nonatomic, copy) NSString *primaryKey;
@property (nonatomic, copy, nullable) void(^additionHandleBlock)(NSMutableDictionary *);
@property (nonatomic, assign, readonly) BOOL finished;

- (instancetype)initWithName:(NSString *)name;

- (void)eventBegin:(NSString *)event;
- (void)eventEnd:(NSString *)event;
- (void)eventEnd:(NSString *)event trackingBeginEvent:(NSString *)beginEvent;
- (void)eventEnd:(NSString *)event trackingEndEvent:(NSString *)endEvent;
- (void)checkPrimaryKey;

- (NSInteger)getDurationBetween:(NSString *)key1 and:(NSString *)key2;
- (void)clear;

- (void)startTrack;
- (void)failedTrackWithErrorCode:(NSInteger)errorCode;
- (void)failedTrackWithErrorCode:(NSInteger)errorCode noEventTracking:(BOOL)noEventTracking;

@end

NS_ASSUME_NONNULL_END
