//
// AWEASMusicCategoryViewController.h
//  AWEStudio
//
//  Created by 李茂琦 on 2018/9/4.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "HTSVideoAudioSupplier.h"

#import <CreationKitInfra/ACCModuleService.h>


@class ACCVideoMusicCategoryModel;

NS_ASSUME_NONNULL_BEGIN

@interface AWEASMusicCategoryViewController : UIViewController<HTSVideoAudioSupplier>

@property (nonatomic, copy) NSString *previousPage;
@property (nonatomic, assign) BOOL shouldHideCellMoreButton;
@property (nonatomic, assign) BOOL isCommerce;
@property (nonatomic, assign) ACCServerRecordMode recordMode;
@property (nonatomic, assign) NSTimeInterval videoDuration;
@property (nonatomic, assign) BOOL disableCutMusic;

- (void)configWithMusicCategoryModelArray:(NSArray<ACCVideoMusicCategoryModel *> *)musicCategoryModelArray;

+ (CGFloat)recommendedHeight:(NSUInteger)numberOfCategories;

@end

NS_ASSUME_NONNULL_END
