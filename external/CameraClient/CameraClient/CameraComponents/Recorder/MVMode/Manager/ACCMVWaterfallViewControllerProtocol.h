//
//  ACCMVWaterfallViewControllerProtocol.h
//  CameraClient
//
//  Created by long.chen on 2020/3/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;
@protocol ACCMVTemplateModelProtocol;

@protocol ACCMVWaterfallViewControllerProtocol <NSObject>

@property (nonatomic, strong) AWEVideoPublishViewModel *publishViewModel;

@property (nonatomic, copy) dispatch_block_t closeBlock;
@property (nonatomic, copy) dispatch_block_t willEnterDetailVCBlock;
@property (nonatomic, copy) dispatch_block_t didAppearBlock;
@property (nonatomic, copy) void (^didPickTemplateBlock)(id<ACCMVTemplateModelProtocol> templateModel);

@end

NS_ASSUME_NONNULL_END
