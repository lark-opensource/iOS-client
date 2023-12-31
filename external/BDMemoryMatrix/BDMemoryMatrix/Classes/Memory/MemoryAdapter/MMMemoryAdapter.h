//
//  WCMemoryAdapter.h
//  Pods-MatrixDemo
//
//  Created by zhufeng on 2021/8/24.
//

#import <Foundation/Foundation.h>
#import "MMMemoryIssue.h"

NS_ASSUME_NONNULL_BEGIN


@protocol MMMemoryAdapterDelegate <NSObject>

@required
- (void)onMemoryIssueReport:(MMMemoryIssue*)issue;
- (void)onMemoryIssueNotFound:(NSString*)errorInfo;

@optional
/// the error code is defined in "memory_stat_err_code.h"
- (void)onMemoryAdapterError:(int)errCode type:(NSString*)type;

- (void)onMemoryAdapterReason:(NSString *)reason type:(NSString *)type;

- (NSDictionary *)onMemoryAdapterGetCustomInfo;

- (void)onMemoryAdapterLog:(NSString*)type content:(NSString*)content;

@end

@interface MMMemoryAdapter : NSObject

@property (nonatomic, weak) id<MMMemoryAdapterDelegate> delegate;

+ (instancetype)shared;

// call when app launch in main thread , before start method
- (void)onAppLaunch;

// call start when need to enable memory hook
- (BOOL)start;

// normally, no need to call stop
- (void)stop;

// report last launch memory data
// call this method when oom detected in last app launch
- (void)report;

//set current viewcontroller name
- (void)setVCName:(char *)name;

- (void)getEventTime:(BOOL)eventTime;

- (void)deleteOldRecords;

@end

NS_ASSUME_NONNULL_END
