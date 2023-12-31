//
//  IESFileDownloadTask.h
//  EffectPlatformSDK
//
//  Created by Keliang Li on 2017/10/30.
//

#import <Foundation/Foundation.h>
#import "IESFileDownloader.h"

@interface IESFileDownloadTask : NSOperation

- (instancetype)initWithURLRequests:(NSArray<NSURLRequest *> *)requests filePath:(NSString *)filePath;

@property (nonatomic, copy) IESFileDownloaderProgress progressBlock;
@property (nonatomic, copy, readonly) NSString   *filePath;
@property (nonatomic, copy, readonly) NSError    *error;
@property (nonatomic, copy, readonly) NSDictionary *extraInfoDict; // e.g. HTTPResponse

@end
