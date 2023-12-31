//
//  BDUGCopyContentItem.m
//  Pods
//
//  Created by 延晋 张 on 16/6/7.
//
//

#import "BDUGCopyContentItem.h"

NSString * const BDUGActivityContentItemTypeCopy         =
@"com.BDUG.ActivityContentItem.Copy";

@implementation BDUGCopyContentItem

- (instancetype)initWithDesc:(NSString *)desc
{
    if (self = [super init]) {
        self.desc = desc;
    }
    return self;
}

-(NSString *)contentItemType
{
    return BDUGActivityContentItemTypeCopy;
}

@end
