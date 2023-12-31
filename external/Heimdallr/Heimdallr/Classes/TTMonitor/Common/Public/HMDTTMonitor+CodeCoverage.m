//
//  HMDTTMonitor+CodeCoverage.m
//
//  Created by wujianguo on 2020/6/15.
//

#import "HMDTTMonitor+CodeCoverage.h"
#import "HMDInfo+AppInfo.h"
#import "HMDFileUploader.h"
#import "HMDInjectedInfo.h"
// PrivateServices
#import "HMDURLSettings.h"

@implementation HMDTTMonitor (CodeCoverage)

+ (void)uploadCodeCoverageFile:(NSString *)filePath
                         scene:(NSString *_Nullable)scene
                  commonParams:(NSDictionary *_Nullable)commonParams
                      callback:(HMDFileUploaderBlock)callback {
    
    HMDFileUploadRequest *request = [HMDFileUploadRequest new];
    request.filePath = filePath;
    request.commonParams = commonParams;
    request.logType = @"code_coverage";
    request.path = [HMDURLSettings classCoverageUploadPath];
    request.scene = scene;
    request.finishBlock = callback;
    
    [[HMDFileUploader sharedInstance] uploadFileWithRequest:request];
}
 @end
