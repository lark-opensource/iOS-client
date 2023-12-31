//
//  BDUGDingTalkContentItem.m
//  Pods
//
//  Created by 张 延晋 on 17/01/09.
//
//

#import "BDUGDingTalkContentItem.h"

NSString * const BDUGActivityContentItemTypeDingTalk      =
@"com.BDUG.ActivityContentItem.dingTalk";

@interface BDUGDingTalkContentItem ()

@end

@implementation BDUGDingTalkContentItem

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
    return BDUGActivityContentItemTypeDingTalk;
}

@end
