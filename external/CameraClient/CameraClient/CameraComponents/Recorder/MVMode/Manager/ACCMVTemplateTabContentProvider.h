//
//  ACCMVTemplateTabContentProvider.h
//  CameraClient
//
//  Created by long.chen on 2020/3/3.
//

#import <Foundation/Foundation.h>

#import "ACCSlidingTabViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCMVCategoryModel, AWEVideoPublishViewModel;
@protocol ACCMVTemplateModelProtocol;

@interface ACCMVTemplateTabContentProvider : NSObject <ACCWaterfallTabContentProviderProtocol>

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, copy) NSArray<ACCMVCategoryModel *> *categories;
@property (nonatomic, copy) dispatch_block_t willEnterDetailVCBlock;
@property (nonatomic, copy) void (^didPickTemplateBlock)(id<ACCMVTemplateModelProtocol> templateModel);
@property (nonatomic, assign) UIEdgeInsets contentInsets;

- (UIView *)acc_zoomTransitionStartViewForItemOffset:(NSInteger)itemOffset;

@end

NS_ASSUME_NONNULL_END
