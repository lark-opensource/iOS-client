//
//  ACCThumbnailDataSource.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/9.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCThumbnailDataSource : NSObject

@property (nonatomic, assign) NSTimeInterval thumbnailInterval;

@property (nonatomic, copy  ) AVAsset *sourceAsset;

@property (nonatomic, assign) CMTimeRange timeRange;

@property (nonatomic, copy, readonly) NSArray<NSValue *> *allTimes;

- (void)generateTimeArray;

- (void)setImageView:(UIImageView *)imageView
            viewSize:(CGSize)viewSize
    placeholderImage:(nullable UIImage *)placeholderImage
           withIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
