//
//  HMDNetworkSpeed.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/2/14.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>


/*!
 @header HMDNetworkSpeed.h
 
 测试网络速度的模块
 1. 网络速度只能算一段时间的平均值
 2. HMDNetworkSpeedData 是数据类型
 3. HMDNetworkSpeedManager 是检测主类 负责定时测速 / 一次性测速
 4. HMDNetworkSpeedManager 如果你不保留这个对象 那么就会停止检测 [ thread_safe ]
 5. 以上请遵守基本的 OC retain/release 法则
 */
@class HMDNetworkSpeedData;


/*!
 @typedef MDNetworkSpeedDataCallback
 @discussion 数据定时回调的 callback
 */
typedef void (^MDNetworkSpeedDataCallback)(HMDNetworkSpeedData * _Nonnull manager);


/*!
 @class HMDNetworkSpeedData
 @discussion 当前网络数据
 */
@interface HMDNetworkSpeedData : NSObject       // 返回数据类

// 网速大小, 包括 cellular & Wi-Fi 单位B/s (bytes/sec)
@property(nonatomic, assign, readonly) CGFloat uploadSpeed_WIFI;
@property(nonatomic, assign, readonly) CGFloat downloadSpeed_WIFI;
@property(nonatomic, assign, readonly) CGFloat uploadSpeed_cellular;
@property(nonatomic, assign, readonly) CGFloat downloadSpeed_cellular;

// 这个等于从手机底部向上划出的快捷操作里面, 开启/关闭 WIFI 和 移动网络的效果 相同
// WIFI 不是只WIFI已经打开, 必须要连接上热点才会反馈Available
@property(nonatomic, assign, readonly, getter=isCellularAvailable) BOOL cellularAvailable;
@property(nonatomic, assign, readonly, getter=isWIFIAvailable) BOOL WIFIAvailable;

// 返回网速实际上是多少秒做的平均值, 理论上无限接近intendedAverageTime
@property(nonatomic, assign, readonly) NSTimeInterval actualAverageTime;

// 字符串化的网速表示 "34 B/s" & "47 MB/s"
+ (nonnull NSString *)stringlizationOfSpeed:(CGFloat)speed;

@end

/*!
 @class HMDNetworkSpeedManager
 
 @discussion 使用方法
 1. 初始化 init / initWithInterval:intendedAverageTime:repeat:
 2. 添加回调 addRegisterWithBlock / removeRegistedBlock
 3. 需要停止 释放这个 HMDNetworkSpeedManager 对象, 无需移除 registeredBlock
 
 @abstract   简单的使用方法
 + averageSpeedOverTimeDuration:withBlockNoRepeat: 测定一段时间网速然后返回一次数据
 */
@interface HMDNetworkSpeedManager : NSObject    // 管理类 (多线程安全)

// 简单的用法: 这个主要是封装了下面的循环定时调用的代码只执行一次
// 注意block的循环保留(self-retained) 这个不像 target-action 是 weak-referenced
+ (void)averageSpeedOverTimeDuration:(NSTimeInterval)duration
                   withBlockNoRepeat:(MDNetworkSpeedDataCallback _Nullable)callback;

- (nonnull instancetype)init; // (方便的标准初始化, 使用缺省

// interval
// 参数决定了多少秒一次在 mainRunloop 上运行 callback, 内部还决定数据采样速率的时间间隔
// (所以说你在子线程上设置需要 callback，而 callback 是会在主线程运行的, 在 callback 中访问多线程数据需要自行加锁)
// 不是说多少秒一次就一定这么快发送, 主线程卡顿可能导致长时间没callback)
// 以设置开始的时间为基准定时返回数据，不是返回后等待多少秒后调用callback)
// intendedAverageTime
// 参数是指返回计划多少秒内平均网速（但不会等这么长才 callback, callback 间隔只取决于 interval ）
// 它只影响读取数据后做平均值运算时会用到多长时间的数据运算(注意 interval 决定了数据采样速率)
- (nonnull instancetype)initWithInterval:(CGFloat)interval              // designated intializer
                     intendedAverageTime:(CGFloat)intendedAverageTime
                                  repeat:(BOOL)repeat NS_DESIGNATED_INITIALIZER;

#pragma mark - Starting callbacks

// 当加入时就自动开始运行了, 在运行时加入, 不会重置 callback 预计时间和间隔
// 返回值: 是block的注册令牌, 你需要停止这个block时传递给removeRegistedBlock即可
- (nonnull id)addRegisterWithBlock:(MDNetworkSpeedDataCallback _Nullable)block;

// 当删除时如果没有其他 block 就自动停止了
- (void)removeRegistedBlock:(nonnull id)blockIndetifier;

// 删除所有的注册Block, 当然这样也就停止了 callback
- (void)removeAllRegistedBlock;

// 额外注释:
// 注意如果不保留这个 Object, 那么会自动停止运行 + dealloc (除非 block 间接保留它导致保留循环)
// 这个也是线程安全的, 不过为了同步, 如果在正在运行时放弃保留Object
// 会在下一次运行时才自动释放资源, 这样实现了线程安全，避免野指针

// Q1: 为什么不在一次返回间隔 interval 里多次采样
//  A: 如果没有去掉特定值运算(如：最高/最低值), 没有啥可优化的
//     多次采样对性能负担大, 优化程度低

// Q2: intendedAverageTime 是做什么的
//  A: 当interval的值过小时, 网速波动过于明显, 此时需要计算一段时间内平均网速较好
//     intendedAverageTime 实际上保留了这么长时间内的数据, 然后做平均运算返回

#pragma mark - Can't set when started

// setting intervals when started will silently omitted
// default to 0.2 seconds, specify zero to get the minimun times
// It is limited to HMDNetworkSpeedIntervalLimit (0.02)
// Any out of range assgin will be constaint to the limited range
@property(nonatomic, assign) CGFloat interval;

// setting intervals when started will silently omitted
// default to 1, this can not be less than intervals
// Any out of range assgin will be constaint to the limited range
@property(nonatomic, assign) CGFloat intendedAverageTime;

// setting intervals when started will silently omitted
// default to YES, if NO auto-remove all objects in message dispatch array
// after any message sent
@property(nonatomic, assign) BOOL repeat;

// Description:
// Actually it tells if there is target-action in the dispatch-array, note that
// even there is target-action in disptach-array, the messages may not be sent due
// to the the result of weak (not retain) property of the target, and it will be
// checked and removed next time this class trying to dispatch messages
@property(nonatomic, readonly, getter=isStarted) BOOL started;

@end
