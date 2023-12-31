//
//  BDUGWechatTimelineContentItem.m
//  Pods
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGWechatTimelineContentItem.h"

NSString * const BDUGActivityContentItemTypeWechatTimeLine    =
@"com.BDUG.ActivityContentItem.wechatTimeLine";

@implementation BDUGWechatTimelineContentItem

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
    return BDUGActivityContentItemTypeWechatTimeLine;
}

@end
