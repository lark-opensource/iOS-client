//
//  BDREStringCompareGraphNode.m
//  BDRuleEngine-Core-Debug-Expression-Fast-Privacy-Service
//
//  Created by Chengmin Zhang on 2022/10/19.
//

#import "BDREStringCmpGraphNode.h"

#import <ByteDanceKit/NSString+BTDAdditions.h>

@interface BDREStringCmpGraphNode()

@property (nonatomic, strong) NSArray<NSString *> *comparedStrs;

- (BOOL)compareStrA:(NSString *)strA strB:(NSString *)strB;

@end

@implementation BDREStringCmpGraphNode

- (instancetype)initWithComparedStrs:(NSArray<NSString *> *)comparedStrs
{
    if (self = [super init]) {
        _comparedStrs = comparedStrs;
    }
    return self;
}

- (void)visitWithFootPrint:(BDREGraphFootPrint *)graphFootPrint previousNode:(BDREGraphNode *)previousNode
{
    [super visitWithFootPrint:graphFootPrint previousNode:previousNode];
    BDRENodeFootPrint *nodeFootPrint = [graphFootPrint nodeFootPrintWithGraphNodeID:[self identifier]];
    NSString *str = (NSString *)[previousNode valueWithFootPrint:graphFootPrint];
    if (![str isKindOfClass:NSString.class]) return;
    for (NSString *cmpStr in self.comparedStrs) {
        if ([self compareStrA:str strB:cmpStr]) {
            nodeFootPrint.calculateRes = YES;
            return;
        }
    }
}

- (BOOL)canPassWithFootPrint:(BDREGraphFootPrint *)graphFootPrint
{
    return [super canPassWithFootPrint:graphFootPrint] && [graphFootPrint nodeFootPrintWithGraphNodeID:[self identifier]].calculateRes;
}

- (BOOL)compareStrA:(NSString *)strA strB:(NSString *)strB
{
    return [strA isEqualToString:strB];
}

@end

@implementation BDREStartWithGraphNode

- (BOOL)compareStrA:(NSString *)strA strB:(NSString *)strB
{
    return [strA hasPrefix:strB];
}

@end

@implementation BDREEndWithGraphNode

- (BOOL)compareStrA:(NSString *)strA strB:(NSString *)strB
{
    return [strA hasSuffix:strB];
}

@end

@implementation BDREContainsGraphNode

- (BOOL)compareStrA:(NSString *)strA strB:(NSString *)strB
{
    return [strA containsString:strB];
}

@end

@implementation BDREMatchesGraphNode

- (BOOL)compareStrA:(NSString *)strA strB:(NSString *)strB
{
    return [strA btd_matchsRegex:strB];
}

@end
