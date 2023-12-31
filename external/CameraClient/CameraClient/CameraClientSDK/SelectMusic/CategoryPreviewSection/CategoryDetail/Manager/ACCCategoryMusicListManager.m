//
//  ACCCategoryMusicListManager.m
//  Aweme
//
//  Created by xiangwu on 2017/4/26.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "ACCCategoryMusicListManager.h"
#import "HTSVideoMusicInfoDataManager.h"
#import "ACCMusicTransModelProtocol.h"
#import <CreationKitArch/ACCMusicModelProtocol.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCLanguageProtocol.h>


@interface ACCCategoryMusicListManager ()
{
    dispatch_queue_t _executeDataQueue;
}

@property (nonatomic, assign, readwrite) BOOL hasMore;
@property (nonatomic, assign) NSInteger cursor;
@property (nonatomic, copy) NSString *cid;
@property (nonatomic, assign) BOOL isRequesting;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) BOOL isCommerce;
@end

@implementation ACCCategoryMusicListManager

- (instancetype)initWithCategoryId:(NSString *)cid
{
    self = [self initWithCategoryId:cid isCommerce:NO];
    return self;
}

- (instancetype)initWithCategoryId:(NSString *)cid
                        isCommerce:(BOOL)isCommerce
                           hasMore:(BOOL)hasMore
                            cursor:(NSInteger)cursor
{
    self = [self initWithCategoryId:cid isCommerce:isCommerce];
    if (self) {
        _hasMore = hasMore;
        _cursor = cursor;
    }
    return self;
}

- (instancetype)initWithCategoryId:(NSString *)cid
                        isCommerce:(BOOL)isCommerce
{
    self = [super init];
    if (self) {
        _cid = [cid copy];
        _executeDataQueue = dispatch_queue_create("category_music_list_queue", DISPATCH_QUEUE_SERIAL);
        _isCommerce = isCommerce;
    }
    return self;
}

- (void)refresh:(ACCCategoryMusicListManagerCompletion)completion {
    if (self.isRequesting) {
        return;
    }
    self.isRequesting = YES;
    self.cursor = 0;
    [self p_loadWithCursor:@(self.cursor) completion:completion];
}

- (void)loadMore:(ACCCategoryMusicListManagerCompletion)completion {
    if (self.isRequesting) {
        return;
    }
    self.isRequesting = YES;
    [self p_loadWithCursor:@(self.cursor) completion:completion];
}

- (void)p_loadWithCursor:(NSNumber *)cursor completion:(ACCCategoryMusicListManagerCompletion)completion {
    [HTSVideoMusicInfoDataManager requestWithMusicClassId:self.cid
                                                   cursor:cursor
                                                    count:nil
                                               isCommerce:self.isCommerce
                                               recordMode:self.recordModel
                                            videoDuration:self.videoDuration
                                               completion:^(ACCVideoMusicListResponse * _Nullable response, NSError * _Nullable error) {
        if (response && !error) {
            if (!ACC_isEmptyString(response.titleModel.name)) {
                self.title = response.titleModel.name;
            }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-retain-self"
            dispatch_async(_executeDataQueue, ^{
#pragma clang diagnostic pop
                NSMutableArray *arr = [[NSMutableArray alloc] init];
                for (NSDictionary *ms in response.mcList) {
                    id<ACCMusicModelProtocol> model = [MTLJSONAdapter modelOfClass:[IESAutoInline(ACCBaseServiceProvider(), ACCMusicTransModelProtocol) musicModelImplClass] fromJSONDictionary:ms error:nil];
                    if (model) {
                        [arr acc_addObject:model];
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.hasMore = response.hasMore.integerValue;
                    self.cursor = response.cursor.integerValue;
                    if ([cursor integerValue] == 0) {
                        self.dataList = arr;
                    } else {
                        [self.dataList addObjectsFromArray:arr];
                    }
                    ACCBLOCK_INVOKE(completion, self.dataList, error);
                    self.isRequesting = NO;
                });
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                ACCBLOCK_INVOKE(completion, self.dataList, error);
                self.isRequesting = NO;
            });
        }

    }];
}

- (NSString *)getMusicListTitle {
    if (!ACC_isEmptyString(self.title)) {
        return self.title;
    } else {
        return ACCLocalizedString(@"com_mig_sound_list", @"音乐列表");
    }
}

@end
