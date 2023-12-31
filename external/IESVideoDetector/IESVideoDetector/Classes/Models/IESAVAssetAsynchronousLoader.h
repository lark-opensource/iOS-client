//
//  IESAVAssetAsynchronousLoader.h
//  CameraClient
//
//  Created by geekxing on 2020/4/10.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "IESAVAsset.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^IESAVAssetAsynchronousLoaderCompletionBlock)(NSArray<IESAVAsset *> * _Nullable assets);

@protocol IESAVAssetAsynchronousLoaderDelegate <NSObject>

@optional

/// Tell us the autoLoaded keys you need. if an empty array is received, the loader will not load `duration` as default as well.
/// @param index Indicating the position in `assets` array.
- (NSArray<NSString *> *)automaticallyLoadedAssetKeysAtIndex:(NSUInteger)index;

/// Given the chance to intercept the loading result of each asset.
/// @param asset `IESAVAsset` object that finishes loading
/// @param index corresponding position in  `assets` array
- (void)statusOfAssetDidChange:(IESAVAsset *)asset atIndex:(NSUInteger)index;

@end

@interface IESAVAssetAsynchronousLoader : NSObject

- (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAssets:(NSArray<AVAsset *> *)assets NS_DESIGNATED_INITIALIZER;

@property (nonatomic, weak) id<IESAVAssetAsynchronousLoaderDelegate> delegate;
@property (nonatomic, assign, getter=isLoading) BOOL loading;

/// Load values of a given set of assets asynchronously
/// @param completion return an array of loaded  `IESAVAsset` objects, which holds a reference to the given `AVAsset`, dispatch on main queue
- (void)loadAssetsAsynchronouslyWithCompletion:(IESAVAssetAsynchronousLoaderCompletionBlock)completion;

- (void)cancelLoading;

@end

NS_ASSUME_NONNULL_END
