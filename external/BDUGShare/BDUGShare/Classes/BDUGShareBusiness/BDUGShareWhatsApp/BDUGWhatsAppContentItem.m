//
//  BDUGWhatsAppContentItem.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/5/29.
//

#import "BDUGWhatsAppContentItem.h"

NSString * const BDUGActivityContentItemTypeWhatsApp = @"com.BDUG.ActivityContentItem.WhatsApp";

@implementation BDUGWhatsAppContentItem

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeWhatsApp;
}

@end
