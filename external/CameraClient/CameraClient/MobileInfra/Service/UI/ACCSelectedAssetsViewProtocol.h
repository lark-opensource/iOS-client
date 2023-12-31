//
//  ACCSelectedAssetsViewProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/9.
//

#import <Foundation/Foundation.h>
#import <CameraClient/AWEAssetModel.h>
#import <CreationKitArch/ACCMVTemplateModelProtocol.h>
#import <CameraClient/ACCSelectedAssetsBottomViewProtocol.h>
#import <CreativeAlbumKit/CAKSelectedAssetsViewProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCSelectedAssetsViewProtocol <CAKSelectedAssetsViewProtocol>

@optional

@property (nonatomic, strong) id<ACCMVTemplateModelProtocol> templateModel;
@property (nonatomic, strong) id<ACCCutSameFragmentModelProtocol> singleFragmentModel;

- (BOOL)checkVideoValidForCutSameTemplate:(CAKAlbumAssetModel *)assetModel;

@end


@protocol ACCSelectedAssetsProtocol <NSObject>

- (UIView<ACCSelectedAssetsViewProtocol> *)selectedAssetsViewWithChangeCellColor:(BOOL) shouldCellChangeColor;

- (UIView<ACCSelectedAssetsBottomViewProtocol> *)selectedAssetsBottomView;

@end

NS_ASSUME_NONNULL_END
