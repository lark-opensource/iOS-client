//
//  AWEDouyinStickerCategoryModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/11/5.
//

#import "AWEDouyinStickerCategoryModel.h"

#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/ACCI18NConfigProtocol.h>

@interface AWEDouyinStickerCategoryModel ()

@end

@implementation AWEDouyinStickerCategoryModel

+ (instancetype)favoriteCategoryModel {
    AWEDouyinStickerCategoryModel *model = [[AWEDouyinStickerCategoryModel alloc] init];
    model.categoryName = ACCLocalizedString(@"profile_favourite", @"收藏");
    model.favorite = YES;
    model.isSearch = NO;
    [model setupForFavorite];
    return model;
}

+ (instancetype)searchCategoryModel
{
    AWEDouyinStickerCategoryModel *model = [[AWEDouyinStickerCategoryModel alloc] init];
    model.categoryName = @"搜索";
    model.categoryKey = @"搜索";
    model.favorite = NO;
    model.isSearch = YES;
    [model setupForSearch];
    return model;
}

- (instancetype)initWithIESCategoryModel:(IESCategoryModel *)model {
    self = [super initWithIESCategoryModel:model];
    if (self) {
        [self setupForFavorite];
        [self parseExtra];
    }
    return self;
}

- (NSArray<NSString *> *)selectedIconUrls {
    return [self.category.selectedIconUrls copy];
}

#pragma mark - Private

- (void)parseExtra {
    NSError *error = nil;
    if (self.category.extra.length == 0) {
        return;
    }
    NSData *data = [self.category.extra dataUsingEncoding:NSUTF8StringEncoding];
    if (data.length) {
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        NSAssert(!error, @"json serialization failed!!! error=%@", error);
        if (error) {
            AWELogToolError(AWELogToolTagNone, @"json serialization failed!!! error=%@", error);
            // 兜底，json解析失败也显示title
            self.categoryName = [self category].categoryName;
        } else {
            BOOL showIconOnly = NO;
            if (json[@"is_show_icon_only"]) {
                showIconOnly = [json[@"is_show_icon_only"] boolValue];
            }
            self.categoryName = showIconOnly ? nil : [self.category.categoryName copy];
        }
    }
}

- (void)setupForFavorite {
    if ([self favorite]) {
        if ([self enableNewFavoritesTitle]) {
            self.categoryName = ACCLocalizedString(@"profile_favourite", @"收藏");
        } else {
            self.categoryName = nil;
            _image = ACCResourceImage(@"iconStickerCollection");
        }
    }
}

- (void)setupForSearch {
    if ([self isSearch]) {
        self.categoryName = nil;
        _image = [UIImage acc_imageWithName:@"ic_prop_search_bar_white"];
    }
}

- (BOOL)enableNewFavoritesTitle {
    NSString *currentLanguage = ACCI18NConfig().currentLanguage;
    return [currentLanguage isEqualToString:@"zh"];;
}

@end
