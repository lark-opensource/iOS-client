//
//  PNSLogUploaderProtocol.h
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/15.
//

#import "PNSServiceCenter.h"

#ifndef PNSLogUploaderProtocol_h
#define PNSLogUploaderProtocol_h

#define PNSLogUploader PNS_GET_INSTANCE(PNSLogUploaderProtocol)

@protocol PNSLogUploaderProtocol <NSObject>

- (void)reportALogWithFetchStartTime:(NSTimeInterval)fetchStartTime
                        fetchEndTime:(NSTimeInterval)fetchEndTime
                               scene:(NSString *_Nonnull)scene
                  reportALogCallback:(void (^_Nonnull)(BOOL success, NSInteger fileCount))reportALogBlock;

- (void)reportALogWithStartTime:(NSTimeInterval)startTime
                        endTime:(NSTimeInterval)endTime;

@end

#endif /* PNSLogUploaderProtocol_h */
