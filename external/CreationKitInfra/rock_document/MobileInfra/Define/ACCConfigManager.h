//
//  ACCConfigManager.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2021/3/9.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCConfigProtocol.h>
#import <CreativeKit/ACCServiceLocator.h>

NS_ASSUME_NONNULL_BEGIN

#define ACCConfigKeyDefaultPair(key, default) (@[key, default])

FOUNDATION_STATIC_INLINE id<ACCConfigGetterProtocol> ACCConfigGetter() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCConfigGetterProtocol)];
}

static inline BOOL ACCConfigBool(NSArray *pair)
{
    return [ACCConfigGetter() boolValueForKeyPath:pair.firstObject defaultValue:[pair.lastObject boolValue]];
}

static inline NSInteger ACCConfigInt(NSArray *pair)
{
    return [ACCConfigGetter() intValueForKeyPath:pair.firstObject defaultValue:[pair.lastObject integerValue]];
}

static inline NSString * ACCConfigString(NSArray *pair)
{
    return [ACCConfigGetter() stringForKeyPath:pair.firstObject defaultValue:pair.lastObject];
}

static inline double ACCConfigDouble(NSArray *pair)
{
    return [ACCConfigGetter() doubleValueForKeyPath:pair.firstObject defaultValue:[pair.lastObject doubleValue]];
}

static inline NSArray * ACCConfigArray(NSArray *pair)
{
    return [ACCConfigGetter() arrayForKeyPath:pair.firstObject defaultValue:pair.lastObject];
}

static inline NSDictionary * ACCConfigDict(NSArray *pair)
{
    return [ACCConfigGetter() dictionaryForKeyPath:pair.firstObject defaultValue:pair.lastObject];
}

#define ACCConfigEnum(pair, enum_type) (enum_type)ACCConfigInt(pair)

NS_ASSUME_NONNULL_END
