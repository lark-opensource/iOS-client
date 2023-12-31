//
//  BDUGEmailContentItem.m
//  Pods
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGEmailContentItem.h"

NSString * const BDUGActivityContentItemTypeEmail         =
@"com.BDUG.ActivityContentItem.Email";

@implementation BDUGEmailContentItem

- (instancetype)initWithTitle:(NSString *)title desc:(NSString *)desc
{
    if (self = [super init]) {
        self.title = title;
        self.desc = desc;
        
        _mimeType = @"image/png";
        _fileName = @"share.png";
    }
    return self;
}

- (NSString *)contentTitle
{
    return @"邮件";
}

-(NSString *)contentItemType
{
    return BDUGActivityContentItemTypeEmail;
}

@end
