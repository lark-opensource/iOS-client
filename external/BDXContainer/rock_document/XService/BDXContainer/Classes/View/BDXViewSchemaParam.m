//
//  BDXViewSchemaParam.m
//  BDXContainer
//
//  Created by tianbaideng on 2021/4/14.
//
#import "BDXViewSchemaParam.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>

@implementation BDXViewSchemaParam

+ (instancetype)paramWithDictionary:(NSDictionary *)dictionary
{
    BDXViewSchemaParam *config = [[BDXViewSchemaParam alloc] init];
    [config updateWithDictionary:dictionary];
    return config;
}

- (void)updateWithDictionary:(NSDictionary *)dict
{
    [super updateWithDictionary:dict];
    self.viewTag = [dict btd_stringValueForKey:@"view_tag"];
}

@end
