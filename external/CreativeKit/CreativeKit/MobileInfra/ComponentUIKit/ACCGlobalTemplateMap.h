//
//  ACCGlobalTemplateMap.h
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/7/18.
//

#import <Foundation/Foundation.h>

typedef Class ACCBusinessTemplateClass;

NS_ASSUME_NONNULL_BEGIN

@interface ACCGlobalTemplateMapImpl : NSObject

+ (instancetype)shareInstance;

- (void)bindExternalTemplate:(ACCBusinessTemplateClass)externalTemplate toInternalTemplate:(ACCBusinessTemplateClass)internalTemplate;

- (NSArray<ACCBusinessTemplateClass> * _Nullable)resolveExternalTemplateWithInternalTemplate:(ACCBusinessTemplateClass)internalTemplate;

@end

FOUNDATION_STATIC_INLINE ACCGlobalTemplateMapImpl * ACCGlobalTemplateMap() {
    return [ACCGlobalTemplateMapImpl shareInstance];
}

NS_ASSUME_NONNULL_END
