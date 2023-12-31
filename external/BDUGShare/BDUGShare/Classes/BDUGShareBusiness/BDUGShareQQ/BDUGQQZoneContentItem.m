//
//  BDUGQQZoneContentItem.m
//  Pods
//
//  Created by 张 延晋 on 16/06/03.
//
//

#import "BDUGQQZoneContentItem.h"

NSString * const BDUGActivityContentItemTypeQQZone        =
@"com.BDUG.ActivityContentItem.qqZone";

@implementation BDUGQQZoneContentItem

@synthesize clickMode = _clickMode, defaultShareType = _defaultShareType;

- (instancetype)initWithTitle:(NSString *)title
                         desc:(NSString *)desc
                   webPageUrl:(NSString *)webPageUrl
                   thumbImage:(UIImage *)thumbImage
                     imageUrl:(NSString *)imageUrl
                     shareTye:(BDUGShareType)defaultShareType
{
    if (self = [super init]) {
        self.title = title;
        self.desc = desc;
        self.webPageUrl = webPageUrl;
        self.imageUrl = imageUrl;
        self.thumbImage = thumbImage;
        self.defaultShareType = defaultShareType;
    }
    return self;
}

-(NSString *)contentItemType
{
    return BDUGActivityContentItemTypeQQZone;
}

@end
