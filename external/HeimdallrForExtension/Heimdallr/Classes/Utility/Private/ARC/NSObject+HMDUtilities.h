//
//  NSObject+Utilities.h
//  HDPro
//
//  Created by Stephen Liu on 12-10-18.
//  Copyright (c) 2012年 Stephen Liu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (HMDPropertyAccess)
+ (NSDictionary *)hmd_properties;
@end

typedef NS_ENUM(NSInteger, NSPropertyType)
{
    NSPropertyTypeUnKnow = 0,
    NSPropertyTypeClass = 1,
    NSPropertyTypeInteger,
    NSPropertyTypeLong,
    NSPropertyTypeLongLong,
    NSPropertyTypeFloat,
    NSPropertyTypeDouble,
    NSPropertyTypeBOOL,
};

@interface GHNSObjectProperty : NSObject
@property (nonatomic, copy)NSString *propertyName;
@property (nonatomic, assign)Class clazz;
@property (nonatomic, assign)NSPropertyType type;
@property (nonatomic, assign)BOOL dynamic;
@property (nonatomic, assign)SEL setter;
@property (nonatomic, assign)SEL getter;
@property (nonatomic, assign)IMP setterImp;
@property (nonatomic, assign)IMP getterImp;
@end
