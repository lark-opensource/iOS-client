//
//  NSObject+Utilities.h
//  HDPro
//
//  Created by Stephen Liu on 12-10-18.
//  Copyright (c) 2012年 Stephen Liu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 属性类型
typedef NS_ENUM(NSUInteger, NSPropertyType) {
    NSPropertyTypeUnknown,
    NSPropertyTypeClass,
    NSPropertyTypeInteger,
    NSPropertyTypeLong,
    NSPropertyTypeLongLong,
    NSPropertyTypeFloat,
    NSPropertyTypeDouble,
    NSPropertyTypeBOOL
};

/// 特定类的单一属性，构成分析
///
/// 仅支持 `可读写` 的属性
@interface GHNSObjectProperty : NSObject

@property (nonatomic, copy)   NSString *name;
@property (nonatomic, assign) NSPropertyType type;
@property (nonatomic, assign) BOOL dynamic;
@property (nonatomic, assign) Class _Nullable cls;

@property (nonatomic, assign) SEL setter;
@property (nonatomic, assign) SEL getter;
@property (nonatomic, assign) IMP setterImpl;
@property (nonatomic, assign) IMP getterImpl;

@end

@interface NSObject (HMDPropertyAccess)

+ (NSDictionary<NSString *, GHNSObjectProperty *> * _Nullable)hmd_properties;

@end

NS_ASSUME_NONNULL_END
