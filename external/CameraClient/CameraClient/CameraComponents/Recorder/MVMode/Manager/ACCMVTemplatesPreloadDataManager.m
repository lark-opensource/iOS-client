//
//  ACCMVTemplatesPreloadDataManager.m
//  CameraClient
//
//  Created by long.chen on 2020/3/13.
//

#import "ACCMVTemplatesPreloadDataManager.h"
#import "ACCMVTemplatesFetchProtocol.h"
#import "ACCCreativePathManager.h"
#import <CreativeKit/ACCMacros.h>

@implementation ACCMVTemplatesPreloadDataManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static ACCMVTemplatesPreloadDataManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [ACCMVTemplatesPreloadDataManager new];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanCached) name:kACCCreativePathExitNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)cleanCached
{
    self.mvTemplatesCategories = @[];
    self.firstPageHotMVTemplates = @[];
}

- (void)preloadMVTemplatesCategoriesAndHotMVTemplatesWithCompletion:(void (^)(BOOL success, ACCMVCategoryModel * _Nullable landingCategory))completion;
{
    self.mvTemplatesCategories = @[];
    self.firstPageHotMVTemplates = @[];
    [ACCMVTemplatesFetch() fetchMVTemplatesCategories:^(NSError * _Nullable error, NSArray<ACCMVCategoryModel *> * _Nullable categories) {
        if (!error && categories) {
            self.mvTemplatesCategories = categories;
            if (categories.count > 1) {
                ACCMVCategoryModel *landingCategory = categories[1];
                [ACCMVTemplatesFetch() refreshMergedMVTemplatesWithCategory:landingCategory
                                                                 completion:^(NSError * _Nullable error,
                                                                              NSArray<id<ACCMVTemplateModelProtocol>> * _Nullable templates,
                                                                              BOOL hasMore,
                                                                              NSNumber * _Nonnull cursor,
                                                                              NSNumber * _Nonnull sortedPosition) {
                    if (!error) {
                        self.firstPageHotMVTemplates = templates;
                        self.hasMore = hasMore;
                        self.cursor = cursor;
                        self.sortedPosition = sortedPosition;
                    }
                    ACCBLOCK_INVOKE(completion, !error, landingCategory);
                }];
                return;
            }
        }
        ACCBLOCK_INVOKE(completion, NO, nil);
    }];
}

@end
