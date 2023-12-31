//
//  BDUGSMSContentItem.m
//  Pods
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGSMSContentItem.h"

NSString * const BDUGActivityContentItemTypeSMS           =
@"com.BDUG.ActivityContentItem.SMS";

@implementation BDUGSMSContentItem

- (instancetype)initWithDesc:(NSString *)desc
{
    if (self = [super init]) {
        self.desc = desc;
    }
    return self;
}

-(NSString *)contentItemType
{
    return BDUGActivityContentItemTypeSMS;
}

@end
