//
//  HMDCPUFreqMonitor.h
//  AWECloudCommand
//
//  Created by zhangxiao on 2021/8/3.
//

#import <Foundation/Foundation.h>

@interface HMDCPUFreqInfo : NSObject

/// current cpu frequency: HZ
@property (nonatomic, assign) NSInteger cpuFreqCurrent;
///  get once cpu frequency operation time usage: ms
@property (nonatomic, assign) NSInteger timeUsage;
/// the cpu standard frequency (design frequency): HZ
@property (nonatomic, assign) NSInteger cpuFreqStandard;
/// the scale (current frequency / standard frequency)
@property (nonatomic, assign) float cpuFreqScale;

@end


@interface HMDCPUFreqMonitor : NSObject

/*
 获取CPU当前频率: !!! 注意该方法不要频繁调用,可能会block主线程或者其他线程,因为在执行这段代码的时候CPU可能会中断原有的工作流程,来执行CPU频率的测试工作,进而会影响或者block住其他线程的工作,待获取到CPU频率之后才能正常运行.
    建议只在怀疑当前CPU被降频时或者从降频恢复时,获取一次就可以

 Get the current CPU frequency: !!! Note that this method should not be called too often, it may block the main thread or other threads, because the CPU may interrupt the original workflow when executing this code to perform the CPU frequency test, which may affect or block the work of other threads, until the CPU frequency is obtained to run normally.
    It is recommended to get the CPU frequency only once when you suspect that the current CPU is downclocked or when you recover from the downclock.
 */
+ (nonnull HMDCPUFreqInfo *)getCurrentCPUFrequency;

@end

