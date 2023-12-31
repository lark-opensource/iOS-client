//
//  ACCMVTemplatesContentProvider.h
//  CameraClient
//
//  Created by long.chen on 2020/3/2.
//

#import <Foundation/Foundation.h>

#import "ACCWaterfallViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCMVCategoryModel, AWEVideoPublishViewModel, IESEffectModel;
@protocol ACCMVTemplateModelProtocol;

@interface ACCMVTemplatesContentProvider : NSObject<ACCWaterfallContentProviderProtocol>

@property (nonatomic, assign) BOOL isLandingCategory;
@property (nonatomic, strong) ACCMVCategoryModel *category;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

@property (nonatomic, copy) dispatch_block_t willEnterDetailVCBlock;
@property (nonatomic, copy) void (^didPickTemplateBlock)(id<ACCMVTemplateModelProtocol> templateModel);
@property (nonatomic, copy) BOOL (^currentVCVisibleBlock)();

- (UIView *)acc_zoomTransitionStartViewForItemOffset:(NSInteger)itemOffset;

@end

NS_ASSUME_NONNULL_END
