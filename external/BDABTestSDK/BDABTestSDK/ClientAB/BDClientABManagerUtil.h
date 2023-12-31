//
//  BDClientABManagerUtil.h
//  ABTest
//
//  Created by ZhangLeonardo on 16/1/24.
//  Copyright © 2016年 ZhangLeonardo. All rights reserved.
//
//  客户端AB测试框架工具类

#import <Foundation/Foundation.h>
#import "BDClientABDefine.h"

/**
 *  客户端AB测试框架工具类
 */
@interface BDClientABManagerUtil : NSObject

/**
 *  生成一个0-999的随机数
 *
 *  @return 0-999的随机数
 */
+ (NSInteger)genARandomNumber;

/**
 *  应用的版本
 *
 *  @return 应用的版本
 */
+ (NSString *)appVersion;

/**
 *  应用的渠道
 *
 *  @return 应用的渠道
 */
+ (NSString *)channelName;

/**
 *  版本号比较
 *
 *  @param leftVersion  要比较的版本号
 *  @param rightVersion 被比较的版本号
 *
 *  @return BDClientABVersionCompareTypeLessThan : leftVersion<rightVersion; 其他类推
 */
+ (BDClientABVersionCompareType)compareVersion:(NSString *)leftVersion toVersion:(NSString *)rightVersion;

@end
