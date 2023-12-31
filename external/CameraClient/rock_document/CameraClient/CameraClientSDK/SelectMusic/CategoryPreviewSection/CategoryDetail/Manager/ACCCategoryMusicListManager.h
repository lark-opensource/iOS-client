//
//  ACCCategoryMusicListManager.h
//  Aweme
//
//  Created by xiangwu on 2017/4/26.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "ACCVideoMusicCategoryModel.h"

#import <CreationKitInfra/ACCModuleService.h>

typedef void(^ACCCategoryMusicListManagerCompletion)(NSArray *list, NSError *error);

@interface ACCCategoryMusicListManager : NSObject

@property (nonatomic, assign, readonly) BOOL hasMore;
@property (nonatomic, strong) NSMutableArray *dataList;
@property (nonatomic, assign) ACCServerRecordMode recordModel;
@property (nonatomic, assign) NSTimeInterval videoDuration;

- (instancetype)initWithCategoryId:(NSString *)cid;
- (instancetype)initWithCategoryId:(NSString *)cid
                        isCommerce:(BOOL)isCommerce;
- (instancetype)initWithCategoryId:(NSString *)cid
                        isCommerce:(BOOL)isCommerce
                           hasMore:(BOOL)hasMore
                            cursor:(NSInteger)cursor;

- (void)refresh:(ACCCategoryMusicListManagerCompletion)completion;
- (void)loadMore:(ACCCategoryMusicListManagerCompletion)completion;
- (NSString *)getMusicListTitle;

@end
