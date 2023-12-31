//
//  ACCGlobalTemplateMap.m
//  CreativeKit-Pods-Aweme
//
//  Created by xiangpeng on 2021/7/18.
//

#import "ACCGlobalTemplateMap.h"

#import <pthread/pthread.h>

@interface ACCGlobalTemplateMapImpl ()

@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray<Class> *> *templateMap;
@property (nonatomic, assign) pthread_mutex_t lock;

@end

@implementation ACCGlobalTemplateMapImpl

+ (instancetype)shareInstance
{
    static dispatch_once_t once;
    static ACCGlobalTemplateMapImpl *shareInstance = nil;

    dispatch_once(&once, ^{
        shareInstance = [[ACCGlobalTemplateMapImpl alloc] init];
    });
    return shareInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        _templateMap = [[NSMutableDictionary alloc] init];
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (void)bindExternalTemplate:(ACCBusinessTemplateClass)externalTemplate toInternalTemplate:(ACCBusinessTemplateClass)internalTemplate
{
    NSString *templateKey = NSStringFromClass(internalTemplate);
    __block NSMutableArray *templateArray = nil;
    
    pthread_mutex_lock(&_lock);
    [self.templateMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<Class> * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:templateKey]) {
            templateArray = obj;
        }
    }];
    if (templateArray) {
        [templateArray addObject:externalTemplate];
    } else {
        templateArray = @[externalTemplate].mutableCopy;
        [self.templateMap setObject:templateArray forKey:templateKey];
    }
    pthread_mutex_unlock(&_lock);
}

- (NSArray<ACCBusinessTemplateClass> *)resolveExternalTemplateWithInternalTemplate:(ACCBusinessTemplateClass)internalTemplate
{
    NSString *templateKey = NSStringFromClass(internalTemplate);
    __block NSArray *templateArray = nil;
    
    pthread_mutex_lock(&_lock);
    [self.templateMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<Class> * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:templateKey]) {
            templateArray = obj;
        }
    }];
    pthread_mutex_unlock(&_lock);
    
    return templateArray;
}


@end
