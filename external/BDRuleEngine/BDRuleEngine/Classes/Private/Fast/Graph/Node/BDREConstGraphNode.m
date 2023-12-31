//
//  BDREConstGraphNode.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import "BDREConstGraphNode.h"

@implementation BDREConstGraphNode

- (instancetype)initWithValue:(id)value
{
    if (self = [super init]) {
        _value = value;
    }
    return self;
}

- (id)valueWithFootPrint:(BDREGraphFootPrint *)graphFootPrint
{
    return self.value;
}

- (BOOL)isEqual:(id)object
{
    if (object == self) return YES;
    if (object == nil || ![object isKindOfClass:[self class]]) return NO;
    id value = ((BDREConstGraphNode *)object).value;
    return [self.value isEqual:value];
}

- (NSUInteger)hash
{
    if (!self.value) return 0;
    return [self.value hash];
}

@end
