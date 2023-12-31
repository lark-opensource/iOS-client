//
//  BDABTestManager.h
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BDABTestBaseExperiment.h"

/**
 接收来自ABSDK的日志，可供调试用
 */
@protocol BDABTestLogDelegate <NSObject>

/**
 接收来自ABSDK的日志，可供调试用
 
 @param log 日志内容
 */
- (void)onLog:(NSString *)log;

@end

/**
 实验管理类。
 
 维护所有被注册的实验model。
 同时提供网络请求、实验取值、获取已曝光的vid的接口。
 */
@interface BDABTestManager : NSObject

/// 锁优化
@property (nonatomic, assign) BOOL enableLockOpt;


/**
 设置ABSDK日志代理，可供调试
 
 同时仅允许存在一个日志代理，每次调用将覆盖之前的delegate
 
 SDK会弱引用这个logDelegate
 
 @param logDelegate 日志代理
 */
+ (void)registerLogDelegate:(id<BDABTestLogDelegate>)logDelegate;

/**
 清除ABSDK日志代理，停止调试
 
 会清除之前设置的日志代理
 */
+ (void)unregisterLogDelegate;

/**
 注册实验。只有已经注册的实验才能取值。
 支持多线程调用
 */
+ (void)registerExperiment:(BDABTestBaseExperiment *)experiment;

/**
 通过指定URL取得改设备命中的实验数据
 支持多线程调用
 
 @param url 指定的url
 @param maxRetryCount 失败后最多重试次数
 */
+ (void)fetchExperimentDataWithURL:(NSString *)url maxRetryCount:(NSInteger)maxRetryCount completionBlock:(void (^)(NSError *error, NSDictionary *data))completionBlock;

/**
 取得key对应的实验的值。只有已经注册的实验才能取值。
 支持多线程调用

 @param key 实验的key
 @param withExposure 取值的同时是否触发曝光
 @return 实验的值
 */
+ (id)getExperimentValueForKey:(NSString *)key withExposure:(BOOL)withExposure;

/**
 已曝光实验的vid
 支持多线程调用

 @return 已曝光实验的vid
 */
+ (NSString *)queryExposureExperiments;

/**
 覆盖修改实验值，服务端实验值可以通过此接口被修改
 
 @param dic 数据，请确保内容合法性！
 格式如下：
 {
 "key1":  {"val": "实验值", "vid": "实验分组的id"},
 "key2":  {"val": "实验值", "vid": "实验分组的id"}
 }
 */
+ (void)saveServerSettingsForServerExperiments:(NSDictionary<NSString *, NSDictionary *> *)dic;

/**
 实验配置界面（测试用），需要业务方自行present
 
 @return 实验配置界面
 */
+ (UIViewController *)panelViewController;

#pragma mark Client AB Experiment

/**
 客户端本地分流实验使用，注册一个本地实验层，重复注册则仅第一次才会成功
 支持多线程调用
 
 @return 注册成功与否结果，重复注册则仅第一次才会成功
 */
+ (BOOL)registerClientLayer:(BDClientABTestLayer *)clientLayer;

/**
 客户端本地分流实验使用，根据层名称获取本地实验层
 支持多线程调用
 
 @return 客户端本地分流实验层，如果不存在、不会创建
 */
+ (BDClientABTestLayer *)clientLayerByName:(NSString *)name;

/**
 *  初始化方法，确保客户端本地分流实验都注册后，才能调用此方法
 *  再次强调，请确保在所有客户端本地分流实验都注册完成后再调用此接口！
 */
+ (void)launchClientExperimentManager;

/**
 *  保存服务器下发的修改，客户端本地分流实验值可以通过此接口被服务端修改，以解决patch问题
 *
 *  @param dict 服务器下发的修改的集合(featurekey:value)
 */
+ (void)saveServerSettingsForClientExperiments:(NSDictionary *)dict;

#pragma mark Legacy

/**
 *  返回当前客户端本地分流实验命中的所有组的vid拼接成的字符串
 *
 *  @return ABGroup 客户端本地分流实验命中的所有组的vid拼接成的字符串
 */
+ (NSString *)ABGroup;

/**
 *  ab version
 *
 *  @return ab version
 */
+ (NSString *)ABVersion;

/**
 *  设置ab version
 *
 *  @param abVersion abVersion
 */
+ (void)saveABVersion:(NSString *)abVersion;

/**
 *  新旧架构    a1表示新架构；a2表示旧架构    5.1
 *  是否为5.1以及5.1之后版本的新用户
 *      b1表示是5.1及之后版本的新用户；
 *      b2表示是5.1之前的版本升级到5.1及之后版本的用户； 5.1
 *  是否是5.4以及5.4之后版本的新用户
 *      b7表示是5.4及之后版本的新用户
 *      b8表示是5.4之前的版本升级到5.4及之后版本的用户
 *  视频or发现    e1【视频】；e2【发现】；     5.1
 *  关心or话题    f1【话题】；f2【关心】；     5.1
 *
 *  @return 拼接后的值
 */
+ (NSString *)ABTestClient;

+ (void)enableEvent:(BOOL)enabled;

@end

