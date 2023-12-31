//
//  BDUGFileDownloadTask.h
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/30.
//

#import <Foundation/Foundation.h>
#import "BDUGFileDownloader.h"

@interface BDUGFileDownloadTask : NSOperation

- (instancetype)initWithURLRequests:(NSArray<NSURLRequest *> *)requests filePath:(NSString *)filePath;

@property (nonatomic, copy) BDUGFileDownloaderProgress progressBlock;

@property (nonatomic, copy, readonly) NSString   *filePath;
@property (nonatomic, copy, readonly) NSError    *error;

- (void)cancelDownloadTask;

@end
