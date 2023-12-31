//
//  BDUGQQFriendContentItem.m
//  Pods
//
//  Created by 张 延晋 on 16/06/03.
//
//

#import "BDUGQQFriendContentItem.h"
#import "BDUGShareAdapterSetting.h"

NSString * const BDUGActivityContentItemTypeQQFriend      =
@"com.BDUG.ActivityContentItem.qqFriend";

@implementation BDUGQQFriendContentItem

@synthesize clickMode = _clickMode, defaultShareType = _defaultShareType;

- (instancetype)initWithTitle:(NSString *)title
                         desc:(NSString *)desc
                   webPageUrl:(NSString *)webPageUr
                   thumbImage:(UIImage *)thumbImage
                     imageUrl:(NSString *)imageUrl
                     shareTye:(BDUGShareType)defaultShareType
{
    if (self = [super init]) {
        self.title = title;
        self.desc = desc;
        self.webPageUrl = webPageUr;
        self.imageUrl = imageUrl;
        self.thumbImage = thumbImage;
        self.defaultShareType = defaultShareType;
    }
    return self;
}

-(NSString *)contentItemType
{
    return BDUGActivityContentItemTypeQQFriend;
}

@end
