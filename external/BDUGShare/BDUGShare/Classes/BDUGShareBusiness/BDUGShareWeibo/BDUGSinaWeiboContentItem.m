//
//  BDUGSinaWeiboContentItem.m
//  Pods
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGSinaWeiboContentItem.h"

NSString * const BDUGActivityContentItemTypeWeibo         = @"com.BDUG.ActivityContentItem.weibo";

@implementation BDUGSinaWeiboContentItem

@synthesize clickMode = _clickMode, defaultShareType = _defaultShareType;

- (instancetype)initWithTitle:(NSString *)title
                         desc:(NSString *)desc
                   webPageUrl:(NSString *)webPageUrl
                        image:(UIImage *)image
                    defaultShareType:(BDUGShareType)defaultShareType

{
    if (self = [super init]) {
        self.title = title;
        self.desc = desc;
        self.webPageUrl = webPageUrl;
        self.image = image;
        self.defaultShareType = defaultShareType;
    }
    return self;
}

-(NSString *)contentItemType
{
    return BDUGActivityContentItemTypeWeibo;
}

@end
