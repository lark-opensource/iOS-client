//
//  BDPMonitorData.h
//  Timor
//
//  Created by dingruoshan on 2019/4/8.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

/// 性能每15秒刷新的数据模型。
@interface BDPMonitorData:NSObject

@property (nonatomic, assign) CGFloat cpuRatio;   // cpu的使用率
@property (nonatomic, assign) CGFloat cpuRatioForSingleApp;   // 单个小程序的cpu使用率
@property (nonatomic, assign) CGFloat fps;        // fps
@property (nonatomic, assign) CGFloat memory;     // 内存
@property (nonatomic, assign) NSInteger freeze;   // 卡顿次数
@property (nonatomic, assign) NSInteger runloopTimes; //

@end

NS_ASSUME_NONNULL_END
