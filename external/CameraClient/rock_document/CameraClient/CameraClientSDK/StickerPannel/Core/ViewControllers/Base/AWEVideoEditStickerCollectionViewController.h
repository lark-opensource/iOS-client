//
//  AWEVideoEditStickerCollectionViewController.h
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/19.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
//TO-DO: 基类移出来
#import "AWEInformationStickerCollectionViewCell.h"
#import "ACCStickerPannelUIConfig.h"
#import "ACCStickerPannelLogger.h"

typedef NS_ENUM(NSInteger, AWEVideoEditStickerCollectionViewStyle) {
    AWEVideoEditStickerCollectionViewStyleNone = 0,
    AWEVideoEditStickerCollectionViewStyleCategorizedWithFooter = 1,
    AWEVideoEditStickerCollectionViewStyleCategorizedWithHeader = 2,
};

NS_ASSUME_NONNULL_BEGIN

@class IESCategoryModel, IESEffectModel, AWEVideoEditStickerCollectionViewController, AWEVideoEditStickerBottomBarViewController;

@protocol AWEVideoEditStickerCollectionVCDelegate <NSObject>

- (void)stickerCollectionViewController:(AWEVideoEditStickerCollectionViewController *)stickerCollectionVC
                       didSelectSticker:(IESEffectModel *)sticker
                                atIndex:(NSInteger)index
                           categoryName:(NSString *)categoryName
                                tabName:(NSString *)tabName
                  downloadProgressBlock:(void(^)(CGFloat))downloadProgressBlock
                        downloadedBlock:(void(^)(void))downloadedBlock;

@end

@interface AWEVideoEditStickerCollectionViewController : UIViewController

@property (nonatomic, weak) id<AWEVideoEditStickerCollectionVCDelegate> delegate;
@property (nonatomic, strong, readonly) AWEVideoEditStickerBottomBarViewController *bottomBarViewController;

//For Subclassing
@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, assign) AWEVideoEditStickerCollectionViewStyle style;
@property (nonatomic, copy) NSArray<IESCategoryModel *> *categories; // 有分类
@property (nonatomic, copy) NSArray<IESEffectModel *> *effects; // 没有分类
@property (nonatomic, assign) CGSize itemSize;
@property (nonatomic, assign) CGFloat horizontalInset;

@property (nonatomic, strong) ACCStickerPannelUIConfig *uiConfig;
@property (nonatomic, strong) id<ACCStickerPannelLogger> logger;

@end

NS_ASSUME_NONNULL_END
