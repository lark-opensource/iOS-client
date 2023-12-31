//
//  ACCFileDownloadTask.h
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/30.
//

#import <Foundation/Foundation.h>
#import "ACCFileDownloader.h"

@interface ACCFileDownloadTask : NSOperation

- (instancetype)initWithURLRequests:(NSArray<NSURLRequest *> *)requests filePath:(NSString *)filePath;

@property (nonatomic, copy) ACCFileDownloaderProgress progressBlock;
@property (nonatomic, copy, readonly) NSString   *filePath;
@property (nonatomic, copy, readonly) NSError    *error;
@property (nonatomic, copy, readonly) NSDictionary *extraInfoDict; // e.g. HTTPResponse

@end
