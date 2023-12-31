//
//  BDRLRawJsonViewModel.m
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by ByteDance on 26.4.22.
//

#import "BDRLRawJsonViewModel.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface BDRLRawJsonViewModel ()<BDRLJsonViewModelProtocol>

@property (nonatomic, strong) NSDictionary *json;

@end

@implementation BDRLRawJsonViewModel

- (NSUInteger)count
{
    return 1;
}

- (instancetype)initWithJson:(NSDictionary *)json
{
    if (self = [super init]) {
        self.json = json;
    }
    return self;
}

- (NSString *)jsonFormat
{
    return [self.json btd_jsonStringPrettyEncoded];
}

@end
