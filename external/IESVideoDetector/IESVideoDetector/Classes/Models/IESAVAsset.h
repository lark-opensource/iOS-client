//
//  IESAVAsset.h
//  CameraClient
//
//  Created by geekxing on 2020/3/31.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, IESAVAssetStatus) {
    IESAVAssetStatusUnknown,
    IESAVAssetStatusReady,
    IESAVAssetStatusFailed,
};

/// Wrapper class for AVAsset async loading
@interface IESAVAsset : NSObject

- (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithAsset:(AVAsset *)asset;
- (instancetype)initWithAsset:(AVAsset *)asset automaticallyLoadedAssetKeys:(nullable NSArray<NSString *> *)automaticallyLoadedAssetKeys NS_DESIGNATED_INITIALIZER;

/*!
@property status
@abstract
   Indicate the asset is already for use or not .

@discussion
   The value of this property is an IESAVAssetStatus that indicates whether the asset can be used.
   When the value of this property is IESAVAssetStatusFailed, the receiver can no longer be used and
   a new instance needs to be created in its place. When this happens, clients can check the value of the error
   property to determine the nature of the failure. This property is key value observable.
*/
@property (readonly) IESAVAssetStatus status;
/*!
 @property error
 @abstract
    If the receiver's status is IESAVAssetStatusFailed, this describes the error that caused the failure.
 
 @discussion
    The value of this property is an NSError that describes what caused the receiver to no longer be able to be used.
    If the receiver's status is not IESAVAssetStatusFailed, the value of this property is nil.
 */
@property (readonly, nullable) NSError *error;

@property (nonatomic, strong, readonly) AVAsset *asset;
@property (nonatomic, assign, readonly) CMTime duration;
@property (nonatomic, assign, readonly) float frameRate;
@property (nonatomic, strong, readonly) AVAssetTrack *videoTrack;
@property (nonatomic, copy, readonly) NSArray<AVAssetTrack *> *audioTracks;
- (float)estimateAudioBitrate;

@end

NS_ASSUME_NONNULL_END
