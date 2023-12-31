//
//  HMDEvilMethodConfig.h
//  AWECloudCommand
//
//  Created by maniackk on 2021/6/3.
//

#import "HMDModuleConfig.h"


extern NSString * _Nullable const kHMDModuleEvilMethodTracer;

@interface HMDEvilMethodConfig : HMDModuleConfig

//单位秒，超过这个卡顿阈值，就认为是慢函数，被记录下来；默认 1.0 s，最小0.5 s
@property(nonatomic, assign) NSTimeInterval hangTime;

// 是否过滤耗时小于millisecond慢函数（并且这个函数内部没有插桩函数），默认YES
// 建议配置YES，可以减少性能损耗。避免火焰图上展示太多耗时很小的函数。
@property (nonatomic, assign) BOOL filterEvilMethod;

//过滤小于filterMillisecond的慢函数；默认值是1ms，并且最小是1ms；
@property (nonatomic, assign) NSInteger filterMillisecond;

@property (nonatomic, assign) BOOL collectFrameDrop;

@property (nonatomic, assign) NSTimeInterval collectFrameDropThreshold;

@end

