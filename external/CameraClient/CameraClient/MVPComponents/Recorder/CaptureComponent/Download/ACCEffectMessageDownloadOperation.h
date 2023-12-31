//
//  ACCEffectMessageDownloadOperation.h
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/11/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCEffectMessageDownloaderCompletedBlock)(NSURL * _Nullable filePath, NSError * _Nullable error);

@interface ACCEffectMessageDownloadOperation : NSOperation

- (instancetype)initWithUrlList:(NSArray<NSString *> *)urlStringList
                  rootDirectory:(NSString *)rootDirectory
                      needUpzip:(BOOL)needUpzip;

- (void)addHandlersForCompleted:(nullable ACCEffectMessageDownloaderCompletedBlock)completedBlock;

@end

NS_ASSUME_NONNULL_END
