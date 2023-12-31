//
//  NSObject+HMDAttributes.h
//  KKShopping
//
//  Created by 刘诗彬 on 14/12/9.
//  Copyright (c) 2014年 Nice. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HMDAttributesMacro.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HMDAttributes <NSObject>

@required

/// 属性(基础类型)对应关系映射
///
/// * 如需默认值，使用 `HMD_ATTR_MAP_DEFAULT` / `HMD_ATTR_MAP_DEFAULT2`
/// * 无需默认值，使用 `HMD_ATTR_MAP`
+ (NSDictionary * _Nullable)hmd_attributeMapDictionary;

@end

typedef void (^HMDAttributeExtraBlock)(NSObject *obj, NSDictionary *dataDict);

@interface NSObject (HMDAttributes) <HMDAttributes>

#pragma mark - Basic

/// 类名
+ (NSString *)hmd_className;

/// 基类(默认: NSObject)
+ (Class)hmd_ancestorClass;

#pragma mark - Initialize

/// 生成对应实例，并使用 dataDict 对该实例的属性赋值
///
/// * 属性对应关系由 `hmd_attributeMapDictionary` 确定
+ (instancetype)hmd_objectWithDictionary:(NSDictionary * _Nullable)dataDict;

/// 生成一组对应实例
+ (NSArray * _Nullable)hmd_objectsWithDictionaries:(NSArray<NSDictionary *> * _Nullable)dataArray;

/// 生成对应实例，并使用 dataDict 对该实例的属性赋值，并处理特殊数据
///
/// * 属性对应关系由 `hmd_attributeMapDictionary` 确定，特殊数据不要在其中声明
/// * 建议优先使用 `hmd_setAttributes:block:` 来处理特殊数据
+ (instancetype)hmd_objectWithDictionary:(NSDictionary * _Nullable)dataDict block:(NS_NOESCAPE HMDAttributeExtraBlock _Nullable)block;

+ (NSArray * _Nullable)hmd_objectsWithDictionaries:(NSArray<NSDictionary *> * _Nullable)dataArray block:(NS_NOESCAPE HMDAttributeExtraBlock _Nullable)block;

#pragma mark - Aggregation

+ (NSDictionary *)hmd_allAttributeMapDictionary;
+ (NSDictionary *)hmd_managedProperties;

#pragma mark - Dictionary to Attributes

/// 使用 dataDict 对属性赋值
///
/// * 属性对应关系由 `hmd_attributeMapDictionary` 确定
- (void)hmd_setAttributes:(NSDictionary * _Nullable)dataDict;

/// 使用 dataDict 对属性赋值，并处理特殊数据
///
/// * 属性对应关系由 `hmd_attributeMapDictionary` 确定，特殊数据不要在其中声明
- (void)hmd_setAttributes:(NSDictionary * _Nullable)dataDict block:(NS_NOESCAPE HMDAttributeExtraBlock _Nullable)block;

#pragma mark - Attributes to Dictionary

/// 由对象生成对应参数列表
///
/// * 属性对应关系由 `hmd_attributeMapDictionary` 确定，且仅包含该方法中声明的属性
/// * 有特殊数据需要处理需求，子类可以继承实现
- (NSDictionary *)hmd_dataDictionary;

@end

NS_ASSUME_NONNULL_END
