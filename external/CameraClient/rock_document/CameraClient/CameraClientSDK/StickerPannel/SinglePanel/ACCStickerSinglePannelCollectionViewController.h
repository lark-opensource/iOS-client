//
//  ACCStickerSinglePannelCollectionViewController.h
//  AAWELaunchOptimization-Pods-DouYin
//
//  Created by liyingpeng on 2020/8/19.
//

#import "AWEVideoEditStickerCollectionViewController.h"
#import "ACCStickerPannelUIConfig.h"

NS_ASSUME_NONNULL_BEGIN

@class IESCategoryModel, ACCStickerPannelDataManager;

@interface ACCStickerSinglePannelCollectionViewController : AWEVideoEditStickerCollectionViewController

@property (nonatomic, strong) IESCategoryModel *category;
@property (nonatomic, strong) ACCStickerPannelDataManager *dataManager;

@end

NS_ASSUME_NONNULL_END
