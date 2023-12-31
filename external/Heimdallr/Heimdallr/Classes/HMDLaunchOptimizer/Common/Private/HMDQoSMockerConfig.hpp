//
//  HMDQoSMockerConfig.h
//  Heimdallr-8bda3036
//
//  Created by xushuangqing on 2022/4/12.
//

#import <Foundation/Foundation.h>
#import <atomic>
#import <string>
#import <unordered_set>

NS_ASSUME_NONNULL_BEGIN

//本次启动的配置
struct HMDQosMockerConfigForCurrentLaunch {
    static bool collectorEnabled;
    static bool qosMockerEnabled;
    static std::atomic_bool launchFinished;
    //由于 C++ 静态变量的构造函数调用晚于 +load，只能让 whiteListQueue new 出来，防止在 +load 中访问了未初始化的变量
    static std::unordered_set<std::string> *whiteListQueue;
};

//+load 结束后，这里的值随时会被更新，作为下一次启动的配置
@interface HMDQoSMockerConfig : NSObject
@property (atomic, assign) BOOL enableQosMocker;
@property (atomic, assign) BOOL enableKeyQueueCollector;
@property (atomic, copy) NSArray *keyQueueNamesArray;
@property (atomic, copy) NSArray *whiteListQueueNames;

+ (instancetype)sharedConfig;
- (id)init __attribute__((unavailable("Use +sharedConfig to retrieve the shared instance.")));
- (void)readFromDisk;
- (void)flush;
- (NSString *)updatedWhiteListQueueName:(NSString *)originQueueName;

@end

NS_ASSUME_NONNULL_END
