//
//  IESDelegateFileDownloadTask.h
//  Pods
//
//  Created by 李彦松 on 2018/10/18.
//

#import <Foundation/Foundation.h>
#import "IESFileDownloader.h"
#import "EffectPlatform.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESDelegateFileDownloadTask : NSOperation

- (instancetype)initWithURL:(NSArray<NSString *> *)urls filePath:(NSString *)filePath;

@property (nonatomic, copy) IESFileDownloaderProgress progressBlock;
@property (nonatomic, copy, readonly) NSString   *filePath;
@property (nonatomic, strong, readonly) NSError    *error;
@property (nonatomic, copy, readonly) NSDictionary *extraInfoDict;
@property (nonatomic, strong) id<EffectPlatformRequestDelegate> requestDelegate;

@end

NS_ASSUME_NONNULL_END
