//
//  ACCWorksPreviewViewControllerProtocol.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/17.
//

#import <Foundation/Foundation.h>
#import "AWECutSameMaterialAssetModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCWorksPreviewViewControllerChangeMaterialCallback)(AWECutSameMaterialAssetModel *replaceMaterialAsset);
typedef void(^ACCWorksPreviewViewControllerChangeMaterialBlock)(NSArray<AWECutSameMaterialAssetModel *> *_Nullable currentMaterialAssets, NSInteger idx, BOOL needReverse, CMTime fragmentDuration, ACCWorksPreviewViewControllerChangeMaterialCallback callback);

@protocol ACCWorksPreviewViewControllerProtocol <NSObject>

@end

NS_ASSUME_NONNULL_END
