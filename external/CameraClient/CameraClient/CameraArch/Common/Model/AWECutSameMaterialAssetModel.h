//
//  AWECutSameMaterialAssetModel.h
//  AWEStudio-Pods-Aweme
//
//  Created by Pinka on 2020/3/25.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCCutSameFragmentModelProtocol.h>
#import <CameraClient/AWEAssetModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWECutSameMaterialAssetModel : NSObject

@property (nonatomic, strong) AWEAssetModel *aweAssetModel;

@property (nonatomic, copy  ) NSURL *currentImageFileURL;

@property (nonatomic, strong) UIImage *currentImage;

@property (nonatomic, copy) NSString *currentImageName;

@property (nonatomic, assign) CGSize currentImageSize;

@property (nonatomic, copy  ) NSURL *processedImageFileURL;

@property (nonatomic, strong) UIImage *processedImage;

@property (nonatomic, copy) NSString *processedImageName;

@property (nonatomic, assign) CGSize processedImageSize;


@property (nonatomic, strong) AVURLAsset *processAsset;

@property (nonatomic, assign) PHImageRequestID requestId;

@property (nonatomic, assign) CGFloat avCompressProgress;

@property (nonatomic, assign) BOOL isReady;

@property (nonatomic, assign) BOOL needReverse;

@end

@interface ACCCutsameMaterialModel : NSObject

@property (nonatomic, strong) AWECutSameMaterialAssetModel *assetModel;
@property (nonatomic, assign) ACCTemplateCartoonType cartoonType;
@property (nonatomic, copy) NSString *gameplayAlgorithm;    // 玩法的算法字段

@end

NS_ASSUME_NONNULL_END
