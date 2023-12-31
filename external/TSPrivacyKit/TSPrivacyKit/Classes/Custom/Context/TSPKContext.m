//
//  TSPKContext.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/28.
//

#import "TSPKContext.h"

#import "TSPKUtils.h"

@interface TSPKContext ()

@property (nonatomic, strong) NSMutableDictionary *dict;

@end

@implementation TSPKContext

- (instancetype)init
{
    if (self = [super init]) {
        _dict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSSet<NSString *> *)contextSymbolsForApiType:(NSString *)apiType
{
    TSPKFetchDetectContextBlock block = self.dict[apiType];
    NSSet *symbols = block ? block() : nil;
    return symbols;
}

- (void)setContextBlock:(TSPKFetchDetectContextBlock)contextBlock forApiType:(NSString *)apiType
{
    if ([apiType length] == 0) {
        return;
    }
    
    _dict[apiType] = contextBlock;
}

@end
