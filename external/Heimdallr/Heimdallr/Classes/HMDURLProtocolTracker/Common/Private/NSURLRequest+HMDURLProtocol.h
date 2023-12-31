//
//  NSURLRequest+HMDURLProtocol.h
//  Heimdallr
//
//  Created by fengyadong on 2018/3/8.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (HMDURLProtocol)

//- (NSMutableURLRequest *)hmd_getPostRequestIncludeBody;
@property (nonatomic, copy) NSString *hmdTempDataFilePath;
@property (nonatomic, assign) NSInteger hmdHTTPBodyStreamLength;

@end


@interface NSMutableURLRequest (HMDURLProtocol)

+ (void)hmd_setupDataTempFolderPath;
- (void)hmd_handlePostRequestBody;
- (void)hmd_handleRequestHeaderFromTraceLogSample;

@end
