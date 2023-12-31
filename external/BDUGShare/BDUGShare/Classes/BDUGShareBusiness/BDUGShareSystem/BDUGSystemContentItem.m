//
//  BDUGSystemContentItem.m
//  Pods
//
//  Created by 延晋 张 on 16/6/6.
//
//

#import "BDUGSystemContentItem.h"

NSString * const BDUGActivityContentItemTypeSystem         =
@"com.BDUG.ActivityContentItem.System";

@implementation BDUGSystemContentItem
@synthesize defaultShareType;

- (instancetype)initWithDesc:(NSString *)desc
                  webPageUrl:(NSString *)webPageUrl
                       image:(UIImage *)image
{
    if (self = [super init]) {
        self.desc = desc;
        self.webPageUrl = webPageUrl;
        self.image = image;
    }
    return self;
}

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeSystem;
}

@end
