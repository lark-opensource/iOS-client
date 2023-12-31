//
//  ACCCanvasMakerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by hongcheng on 2021/1/4.
//

#import <Foundation/Foundation.h>

@class AWEVideoPublishViewModel, AWEAssetModel;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCanvasMakerProtocol <NSObject>

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) dispatch_block_t cancelBlock;
// 纯粹的单图画布(例如非xxx发日常使用的画布技术)，会导出原图以供图集发布
@property (nonatomic, assign) BOOL isPureSinglePhotoCanvas;
- (void)makeCanvasWithAssetModel:(AWEAssetModel *)assetModel completion:(void (^)(BOOL success))completion;
- (void)makeCanvasWithImage:(UIImage *)image done:(void (^)(UIViewController *editor))done;

@end

NS_ASSUME_NONNULL_END
