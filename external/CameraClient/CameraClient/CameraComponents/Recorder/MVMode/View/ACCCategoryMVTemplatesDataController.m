//
//  ACCCategoryMVTemplatesDataController.m
//  CameraClient
//
//  Created by long.chen on 2020/3/6.
//

#import "ACCCategoryMVTemplatesDataController.h"
#import "ACCMVTemplatesFetchProtocol.h"
#import <CreativeKit/ACCMacros.h>


@interface ACCCategoryMVTemplatesDataController ()

@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) BOOL isLoadMoreing;

@end

@implementation ACCCategoryMVTemplatesDataController

@synthesize dataSource = _dataSource;
@synthesize hasMore = _hasMore;
@synthesize cursor = _cursor;
@synthesize categoryModel = _categoryModel;
@synthesize sortedPosition = _sortedPosition;

- (void)refreshContentDataWithCompletion:(void (^)(NSError * _Nonnull, NSArray<id<ACCMVTemplateModelProtocol>> * _Nonnull, BOOL))completion
{
    if (self.isRefreshing) {
        return;
    }
    self.isRefreshing = YES;
    [ACCMVTemplatesFetch() refreshMergedMVTemplatesWithCategory:self.categoryModel
                                                     completion:^(NSError * _Nullable error,
                                                                  NSArray<id<ACCMVTemplateModelProtocol>> * _Nullable templates,
                                                                  BOOL hasMore,
                                                                  NSNumber * _Nonnull cursor,
                                                                  NSNumber * _Nonnull sortedPosition) {
        [self.dataSource removeAllObjects];
        self.cursor = cursor;
        self.hasMore = hasMore;
        self.sortedPosition = sortedPosition;
        if (templates.count) {
            [self.dataSource addObjectsFromArray:templates];
        }
        ACCBLOCK_INVOKE(completion, error, templates, hasMore);
        self.isRefreshing = NO;
    }];
}

- (void)loadMoreContentDataWithCompletion:(void (^)(NSError * _Nonnull, NSArray<id<ACCMVTemplateModelProtocol>> * _Nonnull, BOOL))completion
{
    if (self.isRefreshing || self.isLoadMoreing) {
        return;
    }
    self.isLoadMoreing = YES;
    [ACCMVTemplatesFetch() loadmoreMergedMVTemplatesWithCategory:self.categoryModel
                                                          cursor:self.cursor
                                                  sortedPosition:self.sortedPosition
                                                      completion:^(NSError * _Nullable error,
                                                                   NSArray<id<ACCMVTemplateModelProtocol>> * _Nullable templates,
                                                                   BOOL hasMore,
                                                                   NSNumber * _Nonnull cursor,
                                                                   NSNumber * _Nonnull sortedPosition) {
        self.isLoadMoreing = NO;
        if (!self.dataSource.count) {
            return;
        }
        self.cursor = cursor;
        self.hasMore = hasMore;
        self.sortedPosition = sortedPosition;
        templates = [self p_removeRepetitiveData:templates];
        if (templates.count) {
            [self.dataSource addObjectsFromArray:templates];
        }
        ACCBLOCK_INVOKE(completion, error, templates, hasMore);
    }];
}

- (NSArray<id<ACCMVTemplateModelProtocol>> *)p_removeRepetitiveData:(NSArray<id<ACCMVTemplateModelProtocol>> *)templates
{
    NSUInteger lastFetchCount = self.dataSource.count > [ACCMVTemplatesFetch() fetchCountPerRequest] ? [ACCMVTemplatesFetch() fetchCountPerRequest] : self.dataSource.count;
    NSArray<id<ACCMVTemplateModelProtocol>> *lastFetch = [self.dataSource subarrayWithRange:NSMakeRange(self.dataSource.count - lastFetchCount, lastFetchCount)];
    NSArray<id<ACCMVTemplateModelProtocol>> *result = [templates filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id<ACCMVTemplateModelProtocol> _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        __block BOOL duplicated = NO;
        [lastFetch enumerateObjectsUsingBlock:^(id<ACCMVTemplateModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (evaluatedObject.templateID == obj.templateID) {
                duplicated = YES;
                *stop = YES;
            }
        }];
        return !duplicated;
    }]];
    
    return result.copy;
}

- (NSMutableArray<id<ACCMVTemplateModelProtocol>> *)dataSource
{
    if (!_dataSource) {
        _dataSource = [NSMutableArray array];
    }
    return _dataSource;
}

@end
