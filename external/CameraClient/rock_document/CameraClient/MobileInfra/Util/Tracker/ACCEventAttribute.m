//
//  ACCEventAttribute.m
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import "ACCEventAttribute.h"

@implementation ACCEventAttribute

+ (instancetype)attributeNamed:(NSString *)name
{
    NSAssert(name, @"name can not be nil");
    if (!name) {
        return nil;
    }
    ACCEventAttribute *attribute = [[ACCEventAttribute alloc] init];
    attribute.name = name;
    return attribute;
}

- (ACCEventAttribute *(^)(id))equalTo
{
    return ^id(id value) {
        self.value = value;
        return self;
    };
}

- (void)equalTo:(id(^)(ACCEventAttribute *attribute))block
{
    if (block) {
       self.value = block(self);
    }
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@ = %@", _name, _value];
}

@end
