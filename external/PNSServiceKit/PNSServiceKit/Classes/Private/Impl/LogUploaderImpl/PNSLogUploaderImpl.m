//
//  PNSLogUploaderImpl.m
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/20.
//

#import "PNSLogUploaderImpl.h"
#import "PNSServiceCenter+private.h"
#import <Heimdallr/HMDLogUploader.h>

PNS_BIND_DEFAULT_SERVICE(PNSLogUploaderImpl, PNSLogUploaderProtocol)

@implementation PNSLogUploaderImpl

- (void)reportALogWithFetchStartTime:(NSTimeInterval)fetchStartTime
                        fetchEndTime:(NSTimeInterval)fetchEndTime
                               scene:(NSString * _Nonnull)scene
                  reportALogCallback:(void (^ _Nonnull)(BOOL, NSInteger))reportALogBlock {
    [[HMDLogUploader sharedInstance] reportALogWithFetchStartTime:fetchStartTime
                                                     fetchEndTime:fetchStartTime
                                                            scene:scene
                                               reportALogCallback:reportALogBlock];
}

- (void)reportALogWithStartTime:(NSTimeInterval)startTime
                        endTime:(NSTimeInterval)endTime {
    [[HMDLogUploader sharedInstance] reportALogWithFetchStartTime:startTime
                                                     fetchEndTime:endTime
                                                            scene:@"userexception"
                                               reportALogCallback:nil];
}

@end
