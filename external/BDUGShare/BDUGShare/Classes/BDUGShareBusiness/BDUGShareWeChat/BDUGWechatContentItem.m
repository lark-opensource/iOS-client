//
//  BDUGWechatContentItem.m
//  Pods
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGWechatContentItem.h"

NSString * const BDUGActivityContentItemTypeWechat        =
@"com.BDUG.ActivityContentItem.wechat";

@implementation BDUGWechatContentItem

@synthesize clickMode = _clickMode, defaultShareType = _defaultShareType;

- (instancetype)initWithTitle:(NSString *)title
                         desc:(NSString *)desc
                   webPageUrl:(NSString *)webPageUrl
                   thumbImage:(UIImage *)thumbImage
                    defaultShareType:(BDUGShareType)defaultShareType
{
    if (self = [super init]) {
        self.title = title;
        self.desc = desc;
        self.webPageUrl = webPageUrl;
        self.thumbImage = thumbImage;
        self.defaultShareType = defaultShareType;
    }
    return self;
}

-(NSString *)contentItemType
{
    return BDUGActivityContentItemTypeWechat;
}

@end
