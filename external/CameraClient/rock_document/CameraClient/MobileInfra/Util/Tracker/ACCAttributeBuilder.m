//
//  ACCAttributeBuilder.m
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import "ACCAttributeBuilder.h"

@interface ACCAttributeBuilder ()

@property (nonatomic, strong) NSMutableArray<ACCEventAttribute *> *eventAttributes;

@end

@implementation ACCAttributeBuilder

- (instancetype)init
{
    if (self = [super init]) {
        _eventAttributes = [NSMutableArray array];
    }
    return self;
}

- (ACCEventAttribute *)addAttribute:(NSString *)name
{
    NSAssert(name, @"name can not be nil");
    if (!name) {
        return nil;
    }
    
    ACCEventAttribute *attribute = [ACCEventAttribute attributeNamed:name];
    [_eventAttributes addObject:attribute];
    return attribute;
}

- (ACCEventAttribute * (^)(NSString *))attribute
{
    return ^id(NSString * name) {
        return [self addAttribute:name];
    };
}

- (NSDictionary *)install
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [_eventAttributes enumerateObjectsUsingBlock:^(ACCEventAttribute * _Nonnull attribute, NSUInteger idx, BOOL * _Nonnull stop) {
        [attributes setValue:attribute.value forKey:attribute.name];
    }];
    return [attributes copy];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p>\n%@", NSStringFromClass(self.class), self, [_eventAttributes debugDescription]];
}

@end
