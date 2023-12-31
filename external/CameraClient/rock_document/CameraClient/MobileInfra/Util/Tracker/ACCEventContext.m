//
//  ACCEventContext.m
//  Pods
//
//  Created by chengfei xiao on 2019/8/1.
//

#import "ACCEventContext.h"

@interface ACCEventContext ()
@property (nonatomic, strong) ACCEventContext *baseContext;
@property (nonatomic, strong) NSDictionary *currentAttributes;
@end

@implementation ACCEventContext

+ (instancetype)contextWithContext:(ACCEventContext *)context
{
    ACCEventContext *newContext = [[ACCEventContext alloc] init];
    newContext.baseContext = context.baseContext;
    return newContext;
}

+ (instancetype)contextWithBaseContext:(ACCEventContext *)baseContext
{
    ACCEventContext *newContext = [[ACCEventContext alloc] init];
    newContext.baseContext = baseContext;
    return newContext;
}

- (ACCEventContext *)baseContext
{
    if (!_baseContext) {
        _baseContext = [[ACCEventContext alloc] init];
    }
    return _baseContext;
}

- (NSDictionary *)attributes
{
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSDictionary *baseAttributes = _baseContext.attributes;
    if (baseAttributes) {
        [attributes addEntriesFromDictionary:baseAttributes];
    }
    if (_currentAttributes) {
        [attributes addEntriesFromDictionary:_currentAttributes];
    }
    return attributes;
}

- (instancetype)makeAttributes:(void(^)(ACCAttributeBuilder *))block
{
    ACCAttributeBuilder *attributeBuilder = [[ACCAttributeBuilder alloc] init];
    if (block) {
        block(attributeBuilder);
    }
    self.currentAttributes = [attributeBuilder install];
    return self;
}

- (instancetype)updateAttributes:(void (^)(ACCAttributeBuilder *))block
{
    ACCAttributeBuilder *attributeBuilder = [[ACCAttributeBuilder alloc] init];
    if (block) {
        block(attributeBuilder);
    }
    NSDictionary *attributes = [attributeBuilder install];
    NSMutableDictionary *attributes_ = [NSMutableDictionary dictionary];
    
    if (self.currentAttributes) {
        [attributes_ addEntriesFromDictionary:self.currentAttributes];
    }
    
    if (attributes) {
        [attributes_ addEntriesFromDictionary:attributes];
    }
    
    self.currentAttributes = [attributes_ copy];
    
    return self;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p>\n%@", NSStringFromClass(self.class), self, self.attributes];
}

@end
