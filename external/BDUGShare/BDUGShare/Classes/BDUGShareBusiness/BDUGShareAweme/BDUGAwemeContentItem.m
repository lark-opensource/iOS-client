//
//  BDUGAwemeContentItem.m
//  Pods
//
//  Created by 王霖 on 6/12/16.
//
//

#import "BDUGAwemeContentItem.h"

NSString * const BDUGActivityContentItemTypeAweme = @"com.BDUG.ActivityContentItem.Aweme";

@interface BDUGAwemeContentItem ()

@end

@implementation BDUGAwemeContentItem

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
        self.thumbImage = thumbImage;
        self.imageUrl = imageUrl;
        self.defaultShareType = defaultShareType;
    }
    return self;
}

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeAweme;
}

@end
