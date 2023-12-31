//
//  HMDCaptureBacktrace.h
//  AWECloudCommand
//
//  Created by maniackk on 2020/10/21.
//

#import <Foundation/Foundation.h>


@interface HMDCaptureBacktrace : NSObject

// type 在slardar上看到的类型
// time（单位：秒） 为最大采集时间，超过此时间，停止采集，丢弃数据；采集时间必须大于0，否则返回nil
- (instancetype _Nullable )initCaptureWithType:(NSString * _Nullable)type maxCaptureTime:(NSInteger)time;

/**
 errorTime（单位：毫秒） 最大的误差时间，上传数据之前，先计算误差时间，超过此误差时间丢弃已采集堆栈
 误差时间 = 结束采集时间 -  开始采集时间 - （采集帧数 ➗ 60 ）// 60帧一秒
 */
- (instancetype _Nullable )initCaptureWithType:(NSString * _Nullable)type maxCaptureTime:(NSInteger)time maxErrorTime:(NSInteger)errorTime NS_DESIGNATED_INITIALIZER;

- (instancetype _Nullable )init NS_UNAVAILABLE;
+ (instancetype _Nullable )new NS_UNAVAILABLE;

// 开始采集
- (void)startCapture;

// 结束采集；uploadData是否上传采集到的数据
- (void)stopCapture:(BOOL)uploadData;

@end

