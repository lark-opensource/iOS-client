//
//  LVMediaAsset.h
//  VideoTemplate
//
//  Created by wuweixin on 2020/12/3.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef NS_ENUM(NSUInteger, LVMediaAssetDataType) {
    LVMediaAssetDataTypePicture = 0,
    LVMediaAssetDataTypeVideo,
};

@interface LVMediaAsset : NSObject

@property (nonatomic, copy) NSString *resourceIdentifier;
@property (nonatomic, strong) AVAsset *avAsset;
@property (nonatomic, copy) NSURL *fileURL;
@property (nonatomic, assign) CMTimeRange clipRange;
@property (nonatomic, assign) LVMediaAssetDataType mediaType;
@property (nonatomic, assign) BOOL isReversed;

@property (nonatomic, copy, nullable) NSURL *originImageFileURL; // 原始图片地址

@property (nonatomic, assign, readonly) CGSize naturalSize;
@property (nonatomic, assign, readonly) NSInteger nominalFrameRate;
@property (nonatomic, copy, readonly) NSString *mediaDescription;

@property (nonatomic, assign, readonly) NSUInteger estimatedFrames;

- (BOOL)isValid;
- (BOOL)isAssetEqualTo:(LVMediaAsset *)other;

@end

NS_ASSUME_NONNULL_END
