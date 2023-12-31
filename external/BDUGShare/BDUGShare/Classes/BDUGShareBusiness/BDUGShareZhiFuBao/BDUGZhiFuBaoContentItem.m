//
//  BDUGZhiFuBaoContentItem.m
//  Pods
//
//  Created by 王霖 on 6/12/16.
//
//

#import "BDUGZhiFuBaoContentItem.h"

NSString * const BDUGActivityContentItemTypeZhiFuBao = @"com.BDUG.ActivityContentItem.ZhiFuBao";

@interface BDUGZhiFuBaoContentItem ()

@end

@implementation BDUGZhiFuBaoContentItem

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
        self.thumbImage = thumbImage;
        self.imageUrl = imageUrl;
        self.defaultShareType = defaultShareType;
    }
    return self;
}

- (NSString *)contentItemType
{
    return BDUGActivityContentItemTypeZhiFuBao;
}

@end
