//
//  AWEWaterMarkDownloader.h
//  AWEStudio-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/5/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoFragmentInfo;

typedef void(^AWEWaterMarkCompletionBlock)(NSString * _Nullable fielPath, NSError * _Nullable error);

@interface AWEWaterMarkDownloader : NSObject

+ (void)startDownloadWithTaskId:(NSString *)taskId effectId:(NSString *)effectId imageURLString:(NSString *)URLString completion:(nullable AWEWaterMarkCompletionBlock)completionBlock;

+ (nullable NSString *)imagePathWithTaskId:(nullable NSString *)taskId effectId:(nullable NSString *)effectId;

@end

NS_ASSUME_NONNULL_END
