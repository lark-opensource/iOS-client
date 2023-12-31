//
//  ACCASMusicCategoryManager.h
//  AWEStudio
//
//  Created by 李茂琦 on 2018/9/4.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCModuleService.h>

@class ACCVideoMusicCategoryModel;

typedef void(^AWEASMusicCategoryFetchDataCompletionBlock)(NSArray<ACCVideoMusicCategoryModel *> *list, NSError *error);

@interface ACCASMusicCategoryManager : NSObject

@property (nonatomic, assign) BOOL isCommerce;
@property (nonatomic, assign) ACCServerRecordMode recordMode;
@property (nonatomic, assign) NSTimeInterval videoDuration;

- (void)fetchDataWithCompletion:(AWEASMusicCategoryFetchDataCompletionBlock)completion;

- (ACCVideoMusicCategoryModel *)categoryModel:(NSUInteger)index;

- (NSUInteger)numberOfCategories;

@end
