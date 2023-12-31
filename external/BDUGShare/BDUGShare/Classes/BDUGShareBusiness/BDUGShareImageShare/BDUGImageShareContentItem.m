//
//  BDUGImageShareContentItem.m
//  BDUGShare_Example
//
//  Created by 杨阳 on 2020/3/9.
//  Copyright © 2020 xunianqiang. All rights reserved.
//

#import "BDUGImageShareContentItem.h"

NSString * const BDUGActivityContentItemTypeHiddenMarkImage = @"com.BDUG.ActivityContentItem.hiddenMarkImage";

@implementation BDUGImageShareContentItem

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeHiddenMarkImage;
}

@end
