//
//  BDClientABStorageManager.h
//  ABTest
//
//  Created by ZhangLeonardo on 16/1/24.
//  Copyright © 2016年 ZhangLeonardo. All rights reserved.
//
//  负责ABManager相关需要存储的操作

#import <Foundation/Foundation.h>

/**
 *  负责ABManager相关需要存储的操作
 */
@interface BDClientABStorageManager : NSObject

#pragma mark -- Feature Key

/**
 *  指定的feature key对应的值
 *
 *  @param key 指定的feature key
 *
 *  @return feature key对应的值
 */
- (id)valueForFeatureKey:(NSString *)key;

/**
 *  返回指定featureKey对应的服务端下发的替换本地的setting中的feature值
 *
 *  @param featureKey 指定的featureKey
 *
 *  @return 指定featureKey key对应的值
 */
- (id)serverSettingValueForFeatureKey:(NSString *)featureKey;

/**
 *  直接覆盖重设所有Feature Key数据
 */
- (void)resetFeatureKeys:(NSDictionary *)featureKeys;

/**
 *  直接覆盖重设所有服务端下发的本地分流实验Feature Key数据
 */
- (void)resetServerSettingFeatureKeys:(NSDictionary *)featureKeys;

#pragma mark -- ABGroups 

/**
 *  返回当前版本的各个实验层对应命中的group字典
 *
 *  @return 各个实验层对应命中的group字典
 */
- (NSDictionary *)currentLayer2GroupMap;

/**
 *  存储当前版本计算的各个实验层对应命中的group字典
 *
 *  @param map 各个实验层对应命中的group字典
 */
- (void)saveCurrentVersionLayer2GroupMap:(NSDictionary *)map;

/**
 *  返回当前客户端本地分流实验vid列表
 *
 *  @return vidList 对应的vid列表
 */
- (NSArray *)vidList;

/**
 *  返回当前客户端本地分流实验命中的所有组的vid拼接成的字符串
 *
 *  @return ABGroup 客户端本地分流实验命中的所有组的vid拼接成的字符串
 */
- (NSString *)ABGroup;

/**
 *  存储当前客户端本地分流实验命中的所有组的vid拼接成的字符串
 *
 *  @param ABGroup 客户端本地分流实验命中的所有组的vid拼接成的字符串
 */
- (void)saveABGroup:(NSString *)ABGroup;

#pragma mark -- Random Number

/**
 *  查找随机数字典（层名字与随机数的对应关系表）
 *
 *  @return 查找随机数字典
 */
- (NSDictionary *)randomNumber;

/**
 *  存储随机数字典
 *
 *  @param dict （层名字与随机数的对应关系表）
 */
- (void)saveRandomNumberDicts:(NSDictionary *)dict;

#pragma mark -- AppVersion

/**
 *  存储AppVersion
 *
 *  @param AppVersion AppVersion
 */
- (void)saveAppVersion:(NSString *)AppVersion;

/**
 *  返回AppVersion
 *
 *  @return AppVersion
 */
- (NSString *)AppVersion;

#pragma mark -- ABVersion

/**
 *  存储ABVersion
 *
 *  @param ABVersion ABVersion
 */
- (void)saveABVersion:(NSString *)ABVersion;

/**
 *  返回ABVersion
 *
 *  @return ABVersion
 */
- (NSString *)ABVersion;

#pragma mark -- first install version

/**
 *  第一次安装应用的版本号
 *
 *  @return 第一次安装应用的版本号
 */
+ (NSString *)firstInstallVersionStr;

@end
