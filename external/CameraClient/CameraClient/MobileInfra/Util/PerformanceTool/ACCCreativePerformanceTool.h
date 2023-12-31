//
//  ACCCreativePerformanceTool.h
//  CameraClient-Pods-Aweme
//
//  Created by liumiao on 2020/8/4.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCCreativePerformanceTool : NSObject

+ (void)postRecordInfoWithParams:(NSDictionary *)originalParams;

+ (void)postEditInfoWithParams:(NSDictionary *)originalParams;

+ (void)postPublishInfoWithParams:(NSDictionary *)originalParams;

@end

NS_ASSUME_NONNULL_END
