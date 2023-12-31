//
//  ACCThumbnailCache.h
//  ACCStudio
//
//  Created by Shen Chen on 2019/5/19.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, ACCVideoCompositionRotateType) {
    ACCVideoCompositionRotateTypeNone = 0,
    ACCVideoCompositionRotateTypeRight = 1,
    ACCVideoCompositionRotateTypeDown = 2,
    ACCVideoCompositionRotateTypeLeft = 3,
};

@interface ACCThumbnailRequest : NSObject

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) BOOL fromCache;
- (void)cancel;

@end



typedef NS_ENUM(NSUInteger, ACCThumbnailFetchFor) {
    ACCThumbnailFetchForUnKnown = 0,
    ACCThumbnailFetchForVideoClip,
};

@interface ACCThumbnailCache : NSObject

@property (nonatomic, assign) NSTimeInterval tolerance;

@property (nonatomic, strong, readonly) NSMutableArray<NSNumber *> *generatorDurationArray;

- (ACCThumbnailRequest *)getThumbnailForAsset:(AVAsset *)asset
                                       atTime:(CMTime)time
                                 preferedSize:(CGSize)size
                                     rotation:(ACCVideoCompositionRotateType)rotation
                                   completion:(void (^)(UIImage *image))completion;

@end
