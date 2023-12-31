//
//  ACCASMusicCategoryCollectionTableViewCell.h
//  AWEStudio
//
//  Created by 李茂琦 on 2018/9/10.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "HTSVideoAudioSupplier.h"

#import <CreationKitInfra/ACCModuleService.h>


@class ACCVideoMusicCategoryModel;

@interface ACCASMusicCategoryCollectionTableViewCell : UITableViewCell<HTSVideoAudioSupplier>

// Tracking
@property (nonatomic, copy) NSString *previousPage;
@property (nonatomic, assign) BOOL shouldHideCellMoreButton;
@property (nonatomic, assign) BOOL isCommerce;
@property (nonatomic, assign) ACCServerRecordMode recordMode;
@property (nonatomic, assign) NSTimeInterval videoDuration;
@property (nonatomic, assign) BOOL disableCutMusic;

+ (NSString *)identifier;

+ (CGFloat)recommendedHeight:(NSInteger)numberOfCategories;

- (void)configWithMusicCategoryModelArray:(NSArray<ACCVideoMusicCategoryModel *> *)musicCategoryModelArray;

@end
