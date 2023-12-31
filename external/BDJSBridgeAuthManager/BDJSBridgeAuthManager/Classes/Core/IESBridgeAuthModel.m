//
//  IESBridgeAuthModel.m
//  IESWebKit
//
//  Created by Lizhen Hu on 2019/8/29.
//

#import "IESBridgeAuthModel.h"

#pragma mark - NSObject+Validation

@interface NSObject (Validation)

@end

@implementation NSObject (Validation)

- (id)validatedValueOfClass:(Class)class
{
    return [self isKindOfClass:class] ? self : nil;
}

- (NSArray *)validatedArraryOfStrings
{
    NSArray *array = (NSArray *)self;
    NSMutableArray *validatedMethods = [NSMutableArray array];
    if ([array isKindOfClass:NSArray.class]) {
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:NSString.class]) {
                [validatedMethods addObject:obj];
            }
        }];
    }
    return [validatedMethods copy];
}

@end


#pragma mark - IESBridgeAuthRule

@interface IESBridgeAuthRule ()

@property (nonatomic, copy) NSString *pattern;
@property (nonatomic, assign) IESPiperAuthType group;
@property (nonatomic, copy) NSArray<NSString *> *includedMethods;
@property (nonatomic, copy) NSArray<NSString *> *excludedMethods;

@end

@implementation IESBridgeAuthRule

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _pattern = [aDecoder decodeObjectForKey:@"pattern"];
        _group = [aDecoder decodeIntegerForKey:@"group"];
        _includedMethods = [aDecoder decodeObjectForKey:@"includedMethods"];
        _excludedMethods = [aDecoder decodeObjectForKey:@"excludedMethods"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.pattern forKey:@"pattern"];
    [aCoder encodeInteger:self.group forKey:@"group"];
    [aCoder encodeObject:self.includedMethods forKey:@"includedMethods"];
    [aCoder encodeObject:self.excludedMethods forKey:@"excludedMethods"];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        _pattern = [dict[@"pattern"] validatedValueOfClass:NSString.class];
        
        NSString *group = [dict[@"group"] validatedValueOfClass:NSString.class];
        if ([group isEqualToString:@"private"]) {
            _group = IESPiperAuthPrivate;
        } else if ([group isEqualToString:@"protected"]) {
            _group = IESPiperAuthProtected;
        } else {
            _group = IESPiperAuthPublic;
        }
        
        _includedMethods = [dict[@"included_methods"] validatedArraryOfStrings];
        _excludedMethods = [dict[@"excluded_methods"] validatedArraryOfStrings];
    }
    return self;
}

- (instancetype)initWithPattern:(NSString *)pattern group:(IESPiperAuthType)group
{
    self = [super init];
    if (self) {
        _pattern = [pattern copy];
        _group = group;
    }
    return self;
}

@end

#pragma mark - IESOveriddenMethodPackage

@implementation IESOverriddenMethodPackage

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _publicMethods = [aDecoder decodeObjectForKey:@"publicMethods"];
        _protectedMethods = [aDecoder decodeObjectForKey:@"protectedMethods"];
        _privateMethods = [aDecoder decodeObjectForKey:@"privateMethods"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.publicMethods forKey:@"publicMethods"];
    [aCoder encodeObject:self.protectedMethods forKey:@"protectedMethods"];
    [aCoder encodeObject:self.privateMethods forKey:@"privateMethods"];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict{
    self = [super init];
    if (self) {
        _publicMethods = [NSMutableSet setWithArray:[dict[@"public"] validatedArraryOfStrings]];
        _protectedMethods = [NSMutableSet setWithArray:[dict[@"protected"] validatedArraryOfStrings]];
        _privateMethods = [NSMutableSet setWithArray:[dict[@"private"] validatedArraryOfStrings]];
    }
    return self;
}

- (BOOL)containsMethodName:(NSString *)methodName{
    if ([self.publicMethods containsObject:methodName]){
        return YES;
    }
    if ([self.protectedMethods containsObject:methodName]){
        return YES;
    }
    if ([self.privateMethods containsObject:methodName]){
        return YES;
    }
    return NO;
}

@end

#pragma mark - IESBridgeAuthPackage

NSString * const IESBridgeAuthInfoChannel = @"_jsb_auth";

@interface IESBridgeAuthPackage ()

@property (nonatomic, assign) NSInteger type;
@property (nonatomic, copy) NSString *channel;
@property (nonatomic, copy) NSDictionary<NSString *, NSArray<IESBridgeAuthRule *> *> *content;

@end

@implementation IESBridgeAuthPackage

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _type = [aDecoder decodeIntegerForKey:@"type"];
        _channel = [aDecoder decodeObjectForKey:@"channel"];
        _content = [aDecoder decodeObjectForKey:@"content"];
        _overriddenMethodPackage = [aDecoder decodeObjectForKey:@"overridden_methods"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.type forKey:@"type"];
    [aCoder encodeObject:self.channel forKey:@"channel"];
    [aCoder encodeObject:self.content forKey:@"content"];
    [aCoder encodeObject:self.overriddenMethodPackage forKey:@"overridden_methods"];
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        _type = [[dict[@"package_type"] validatedValueOfClass:NSNumber.class] integerValue];
        _channel = [dict[@"channel"] validatedValueOfClass:NSString.class];
        _content = [self validatedContentWithDict:dict[@"content"]];
        if ([[dict objectForKey:@"overridden_methods"] isKindOfClass:NSDictionary.class]){
            _overriddenMethodPackage = [[IESOverriddenMethodPackage alloc] initWithDictionary:dict[@"overridden_methods"]];
        }
    }
    return self;
}

- (NSString *)namespace
{
    return [self.channel containsString:@"."] ? [self.channel componentsSeparatedByString:@"."].lastObject : IESPiperDefaultNamespace;
}

- (BOOL)isBridgeAuthInfo
{
    return self.type == 3 && [self.channel hasPrefix:IESBridgeAuthInfoChannel];
}

- (NSDictionary *)validatedContentWithDict:(NSDictionary *)content {
    NSMutableDictionary *rules = [NSMutableDictionary dictionary];
    if ([content isKindOfClass:NSDictionary.class]) {
        [content enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *objs, BOOL *stop) {
            NSMutableArray *array = [NSMutableArray array];
            if ([objs isKindOfClass:NSArray.class]) {
                [objs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    if ([obj isKindOfClass:NSDictionary.class]) {
                        IESBridgeAuthRule *rule = [[IESBridgeAuthRule alloc] initWithDictionary:obj];
                        if (rule) {
                            [array addObject:rule];
                        }
                    }
                }];
            }
            if ([key isKindOfClass:NSString.class]) {
                rules[key] = [array copy];
            }
        }];
    }
    return [rules copy];
}

@end

@implementation IESBridgeAuthRequestParams

@end
