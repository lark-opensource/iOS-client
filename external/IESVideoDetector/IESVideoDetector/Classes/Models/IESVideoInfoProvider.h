//
//  IESVideoInfoProvider.h
//  CameraClient
//
//  Created by geekxing on 2020/4/3.
//

#import "IESAVAssetAsynchronousLoader.h"
#import "IESVideoInfo.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^IESVideoInfoProviderCompletionBlock)(NSArray<IESVideoInfo *> * _Nullable videoInfos);

@interface IESVideoInfoProvider : IESAVAssetAsynchronousLoader

/// Load essential video infos from an array of assets
/// @param completion return an array of  `IESVideoInfo` objects, dispatch on main queue
- (void)loadVideoInfosWithCompletion:(IESVideoInfoProviderCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
