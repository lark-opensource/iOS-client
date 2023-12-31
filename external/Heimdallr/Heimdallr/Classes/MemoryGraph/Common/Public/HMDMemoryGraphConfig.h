//
//  HMDMemoryGraphConfig.h
//  Pods
//
//  Created by fengyadong on 2020/02/21.
//

#import <Foundation/Foundation.h>
#import "HMDModuleConfig.h"

extern NSString *const kHMDModuleMemoryGraph;//线上memory graph监控

@interface HMDMemoryGraphConfig : HMDModuleConfig

@property (nonatomic, assign) BOOL manualMemoryWarning;//memory graph生成之前是否手动发出内存警告的通知，用来排除一些可以释放的缓存占用，默认NO
@property (nonatomic, assign) NSTimeInterval checkInterval;//定时监测物理内存大小的间隔，默认5s
@property (nonatomic, assign) NSUInteger dangerThresholdMB;//物理内存危险占用的阈值，默认1GB
@property (nonatomic, assign) NSUInteger growingStepMB;//物理内存到达危险阈值后阈值的增幅，防止到达阈值后频繁dump，造成更大的性能损耗，默认200MB
@property (nonatomic, assign) NSUInteger devicePerformanceLevelThreshold;//支持开启的设备性能等级的阈值（即等级>=此阈值），默认2，不包括iPhone6s之前设备。设备性能等级定义见：HMDInfo+DeviceInfo.h
@property (nonatomic, assign) NSUInteger minGenerateMinuteInterval;//一次使用期间两次内存分析之间最小的时间间隔，默认20分钟，时间+超过阈值同时满足再进行下一次分析
@property (nonatomic, assign) NSUInteger maxTimesPerDay;//一天之内对单个用户可以触发的最大次数，默认10次
@property (nonatomic, assign) NSUInteger minRemainingMemoryMB;//使用memory graph，需要最少的内存空间
@property (nonatomic, assign) NSUInteger maxFileSizeMB;//memory graph生成的文件尺寸的最大值，单位MB
@property (nonatomic, assign) NSUInteger maxPreparedFolderSizeMB; //memorygraph待上传的压缩包文件夹大小最大值，默认超过500MB，就全量上传。（正常情况，一个压缩包30MB左右，如果这个文件夹很大，说明积压上传不了）注意：这个值设置小于200MB，也会设置成200，避免手误设置错了。
@property (nonatomic, assign) BOOL enableCPPSymbolicate;//是否在本地做C++符号的符号化
@property (nonatomic, assign) NSUInteger timeOutInterval;//挂起线程超时时长
@property (nonatomic, assign) BOOL enableLeakNodeCalibration;//是否进行泄漏内存节点校准
@property (nonatomic, assign) BOOL calculateSlardarMallocMemory; //内存阈值是否包含slardar_malloc的内存
@property (nonatomic, assign) NSUInteger memorySurgeThresholdMB;//内存突增判定值，默认500MB
@property (nonatomic, assign) BOOL enableCFInstanceSymbolicate;//是否需要开启cf对象的符号化
/// 已废弃
@property (nonatomic, assign) BOOL enableRefAccuracyImprove __attribute__((deprecated("use enableCircularReferenceDetect instead")));
@property (nonatomic, assign) BOOL enableCircularReferenceDetect;

@end
