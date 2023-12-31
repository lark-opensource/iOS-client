//
//  HMDAppExitReasonDetector+LogUpload.h
//  Heimdallr
//
//  Created by Ysurfer on 2023/3/3.
//

#import "HMDAppExitReasonDetector.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDAppExitReasonDetector (LogUpload)

+ (void)uploadMemoryInfoAsync;
+ (void)deleteLastMemoryInfo;
+ (NSString * _Nonnull)memoryLogProcessingPath;

@end

NS_ASSUME_NONNULL_END
