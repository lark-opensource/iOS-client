//
//  BDABTestBaseExperiment.h
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BDABTestValueType) {
    BDABTestValueTypeNumber,
    BDABTestValueTypeString,
    BDABTestValueTypeArray,
    BDABTestValueTypeDictionary
};
typedef id(^BDABSettingsValueBlock)(NSString *key);

@interface BDABTestBaseExperiment : NSObject

/**
 Experiment key, must be same as "Parameter config" on Libra.
 */
@property (nonatomic, copy, readonly) NSString *key;

/**
 Owner of the Experiment
 */
@property (nonatomic, copy, readonly) NSString *owner;

/**
 Experiment description
 */
@property (nonatomic, copy, readonly) NSString *desc;

/**
 Default Value of the experiment.
 */
@property (nonatomic, strong, readonly) id defaultValue;

/**
 Type of the experiment value.
 */
@property (nonatomic, assign, readonly) BDABTestValueType valueType;

/**
 If set to true, the value of the experiment remains the same during this session.
 */
@property (nonatomic, assign, readonly) BOOL isSticky;

/**
 Initialization of the experiment
 
 @param key Experiment key, must be the same as Libra. 
 @param owner Experiment owner.
 @param description Experiment descriptin.
 @param defaultValue Default value of the experiment.
 @param valueType Type of the experiment value.
 @param isSticky If set to YES, the value remains the same during this session.
 @return BDABTestBaseExperiment instance
 */
- (instancetype)initWithKey:(NSString *)key
                      owner:(NSString *)owner
                description:(NSString *)description
               defaultValue:(id)defaultValue
                  valueType:(BDABTestValueType)valueType
                   isSticky:(BOOL)isSticky;

/**
 Experiment initialization

 @param key Experiment key, must be the same as Libra. 
 @param owner Experiment owner.
 @param description Experiment descriptin.
 @param defaultValue Default value of the experiment.
 @param valueType Type of the experiment value.
 @param isSticky If set to YES, the value remains the same during this session.
 @param settingsValueBlock Use this block when the user didn't get any value from the experiment. This block manually gets value from Settings.
 @return BDABTestBaseExperiment instance
 */
- (instancetype)initWithKey:(NSString *)key
                      owner:(NSString *)owner
                description:(NSString *)description
               defaultValue:(id)defaultValue
                  valueType:(BDABTestValueType)valueType
                   isSticky:(BOOL)isSticky
         settingsValueBlock:(BDABSettingsValueBlock)settingsValueBlock;

/**
 Get Experiment value.
 Multi-thread safe.

 @param withExposure 
 @return Experiment value
 */
- (id)getValueWithExposure:(BOOL)withExposure;

@end

#pragma mark Client AB Experiment

@class BDClientABTestLayer;

@interface BDClientABTestExperiment : BDABTestBaseExperiment

/**
 客户端本地分流使用，该实验所在的层，同一层的实验可以互斥地分享流量，不同层实验可互不干扰地同时进行
 */
@property (nonatomic, copy, readonly) BDClientABTestLayer *clientLayer;

/**
 实验的初始化
 
 @param key 实验key，必须与libra平台的“配置参数”名字保持一致
 @param owner 实验的负责人
 @param description 实验的说明
 @param defaultValue 实验的默认值
 @param valueType 这个实验值的预期类型
 @param isSticky 该实验的取值，是否需要在一次启动期间保持一致
 @param clientLayer 客户端本地分流使用，该实验所在的层，同一层的实验可以互斥地分享流量，不同层实验可互不干扰地同时进行
 @return BDABTestBaseExperiment对象
 */
- (instancetype)initWithKey:(NSString *)key
                      owner:(NSString *)owner
                description:(NSString *)description
               defaultValue:(id)defaultValue
                  valueType:(BDABTestValueType)valueType
                   isSticky:(BOOL)isSticky
                 clientLayer:(BDClientABTestLayer *)clientLayer;

@end

/**
 客户端本地分流实验组信息
 */
@interface BDClientABTestGroup : NSObject

/**
 实验组groupID（vid），全局唯一（目前内容都是整型数字）
 */
@property (nonatomic, copy, readonly) NSString *name;

/**
 每一层实验区划分为0～999区间，生成随机数时落到哪个组的区间内就命中哪个实验组，本组区间的起始点，如“300”
 */
@property (nonatomic, assign, readonly) NSInteger minRegion;

/**
 每一层实验区划分为0～999区间，生成随机数时落到哪个组的区间内就命中哪个实验组，本组区间的终结点，如“599”
 */
@property (nonatomic, assign, readonly) NSInteger maxRegion;

/**
 实验组的结果取值，每个实验key对应value的字典形式
 */
@property (nonatomic, copy, readonly) NSDictionary *results;

/**
 初始化方法
 */
- (instancetype)initWithName:(NSString *)name minRegion:(NSInteger)minRegion maxRegion:(NSInteger)maxRegion results:(NSDictionary *)results;

/**
 校验合法性
 */
- (BOOL)isLegal;

@end

/**
 客户端本地分流Layer的属性，主要为客户端本地分流使用
 */
@interface BDClientABTestLayer : NSObject

/**
 层名称，也是层的唯一标识，同一层的实验可以互斥地分享流量，必选
 */
@property (nonatomic, copy, readonly) NSString *name;

/**
 层的分组集，必选
 */
@property (nonatomic, copy) NSArray<BDClientABTestGroup *> *groups;

/**
 层的过滤条件集，可选
 */
@property (nonatomic, copy) NSDictionary *filters;

/**
 本地实验层的初始化方法
 */
- (instancetype)initWithName:(NSString *)name groups:(NSArray *)groups;

/**
 校验合法性
 */
- (BOOL)isLegal;

@end
