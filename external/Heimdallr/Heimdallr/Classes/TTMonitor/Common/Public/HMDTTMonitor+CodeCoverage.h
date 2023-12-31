//
//  HMDTTMonitor+CodeCoverage.h
//
//  Created by wujianguo on 2020/6/15.
//

#import "HMDTTMonitor.h"
#import "HMDFileUploadRequest.h"

@interface HMDTTMonitor (CodeCoverage)

+ (void) uploadCodeCoverageFile : (NSString *_Nonnull)filePath scene:(NSString * _Nullable)scene commonParams:(NSDictionary * _Nullable)commonParams callback:(HMDFileUploaderBlock _Nullable ) callback;

@end

