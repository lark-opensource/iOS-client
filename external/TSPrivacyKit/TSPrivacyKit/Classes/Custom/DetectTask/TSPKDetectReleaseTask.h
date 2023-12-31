//
//  TSPKReleaseDetectTask.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import <Foundation/Foundation.h>

#import "TSPKDetectTask.h"

@interface TSPKDetectResult : NSObject

@property (nonatomic, assign) BOOL isRecordStopped;
@property (nonatomic, copy, nullable) NSString *instanceAddress;

@end

@interface TSPKDetectReleaseTask : TSPKDetectTask

@property (nonatomic, assign) BOOL ignoreSameReport;

- (void)setup;

- (void)handleDetectResult:(nonnull TSPKDetectResult *)result
           detectTimeStamp:(NSTimeInterval)detectTimeStamp
                     store:(nullable id<TSPKStore>)store
                      info:(nullable NSDictionary *)dict;

- (void)executeWithInstanceAddressAndScheduleTime:(NSString *_Nullable)instanceAddress scheduleTime:(NSTimeInterval)scheduleTime;

@end

