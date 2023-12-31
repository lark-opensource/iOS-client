//
//  BDREEntryGraphNode.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/13.
//

#import "BDREEntryGraphNode.h"
#import "BDREGraphFootPrint.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface BDREEntryGraphNode ()

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong) NSMutableDictionary<id<NSCopying>, BDREConstGraphNode *> *map;

@end

@implementation BDREEntryGraphNode

- (instancetype)initWithIdentifier:(NSString *)identifier
{
    if (self = [super init]) {
        _identifier = identifier;
        _map = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)connectToConstNode:(BDREConstGraphNode *)constNode;
{
    [self.map btd_setObject:constNode forKey:[constNode valueWithFootPrint:nil]];
}

- (void)travelWithFootPrint:(BDREGraphFootPrint *)graphFootPrint
{
    if (![self canPassWithFootPrint:graphFootPrint]) {
        return;
    }
    id obj = [self valueWithFootPrint:graphFootPrint];
    if (self.isCollection) {
        if (![obj isKindOfClass:NSArray.class] && ![obj isKindOfClass:NSSet.class]) {
            return;
        }
        for (id eachObj in obj) {
            BDREGraphNode *node = [self.map btd_objectForKey:eachObj default:nil];
            if (node) {
                [node visitWithFootPrint:graphFootPrint previousNode:self];
                [node travelWithFootPrint:graphFootPrint];
            }
        }
    } else {
        BDREGraphNode *node = [self.map btd_objectForKey:obj default:nil];
        if (node) {
            [node visitWithFootPrint:graphFootPrint previousNode:self];
            [node travelWithFootPrint:graphFootPrint];
        } else {
            if ([obj isKindOfClass:NSNumber.class] && [obj isEqualToNumber:@0]) {
                return;
            }
        }
    }
    [super travelWithFootPrint:graphFootPrint];
}

- (id)valueWithFootPrint:(BDREGraphFootPrint *)graphFootPrint
{
    return [graphFootPrint paramValueForName:self.identifier isRegistered:self.isRegisterParam];
}

@end
