//
//  ACCASMusicCategoryManager.m
//  CameraClient
//
//  Created by 李茂琦 on 2018/9/4.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "ACCASMusicCategoryManager.h"
#import "HTSVideoMusicInfoDataManager.h"
#import "ACCVideoMusicCategoryModel.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

@interface ACCASMusicCategoryManager ()

@property (nonatomic, copy) NSArray<ACCVideoMusicCategoryModel *> *dataList;

@end

@implementation ACCASMusicCategoryManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dataList = [[NSArray alloc] init];
    }
    return self;
}

- (void)fetchDataWithCompletion:(AWEASMusicCategoryFetchDataCompletionBlock)completion
{
    @weakify(self);
    [HTSVideoMusicInfoDataManager requestWithCursor:nil
                                              count:nil
                                         isCommerce:self.isCommerce
                                         recordMode:self.recordMode
                                      videoDuration:self.videoDuration
                                         completion:^(ACCVideoMusicListResponse * _Nullable response, NSError * _Nullable error) {
        @strongify(self);
        if (!error && response) {
            NSMutableArray *arr = [[NSMutableArray alloc] init];
            NSMutableSet *set = [[NSMutableSet alloc] init];
            [response.mcList enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                ACCVideoMusicCategoryModel *model = [MTLJSONAdapter modelOfClass:ACCVideoMusicCategoryModel.class fromJSONDictionary:obj error:nil];
                if (model && model.name) {
                    if (![set containsObject:model.name]) {
                        [arr acc_addObject:model];
                        [set addObject:model.name];
                    }
                }
            }];
            self.dataList = [arr copy];
        }
        ACCBLOCK_INVOKE(completion, self.dataList, error);
    }];
}

- (ACCVideoMusicCategoryModel *)categoryModel:(NSUInteger)index
{
    if (ACC_isEmptyArray(self.dataList) || index >= self.dataList.count) {
        return nil;
    }
    return [self.dataList acc_objectAtIndex:index];
}

- (NSUInteger)numberOfCategories
{
    return ACC_isEmptyArray(self.dataList) ? 0 : self.dataList.count;
}

@end
