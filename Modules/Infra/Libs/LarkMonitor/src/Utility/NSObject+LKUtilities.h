//
//  NSObject+LKUtilities.h
//  LarkMonitor
//
//  Created by sniperj on 2020/11/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (LKUtilities)

+ (NSDictionary *)lk_properties;

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

@interface LKObjectProperty : NSObject
@property (nonatomic, copy)NSString *propertyName;
@property (nonatomic, assign)Class clazz;
@property (nonatomic, assign)NSPropertyType type;
@property (nonatomic, assign)BOOL dynamic;
@property (nonatomic, assign)SEL setter;
@property (nonatomic, assign)SEL getter;
@property (nonatomic, assign)IMP setterImp;
@property (nonatomic, assign)IMP getterImp;
@end

NS_ASSUME_NONNULL_END
