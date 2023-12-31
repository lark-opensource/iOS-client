//
//  ACCThumbnailDataSource.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/9.
//

#import "ACCThumbnailDataSource.h"
#import "UIImageView+ACCThumbnail.h"
#import "ACCThumbnailCache.h"
#import <CreativeKit/ACCMacros.h>

@interface ACCThumbnailDataSource ()

@property (nonatomic, strong) ACCThumbnailCache *thumbnailCache;

@property (nonatomic, copy, readwrite) NSArray<NSValue *> *allTimes;

@end

@implementation ACCThumbnailDataSource

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _thumbnailCache = [[ACCThumbnailCache alloc] init];
    }
    
    return self;
}

- (void)generateTimeArray
{
    NSTimeInterval interval = self.thumbnailInterval;
    if (interval <= 0) {
        return ;
    }
    
    //计算每个片段需要多少个图片
    NSInteger segCount = ceil(CMTimeGetSeconds(self.timeRange.duration) / interval);
    NSMutableArray *timeArrayRelativeToSeg = [[NSMutableArray alloc] init];
    CMTime maxTime = CMTimeAdd(self.timeRange.start, self.timeRange.duration);
    for (int i = 0; i < segCount; i++) {
        CMTime frameTimeRelativeToSeg = CMTimeAdd(self.timeRange.start,
                                                  CMTimeMakeWithSeconds(i * interval, self.timeRange.duration.timescale));
        if (CMTimeCompare(frameTimeRelativeToSeg, maxTime) > 0) {
            frameTimeRelativeToSeg = maxTime;
        }
        [timeArrayRelativeToSeg addObject:[NSValue valueWithCMTime:frameTimeRelativeToSeg]];
    }
    
    self.allTimes = timeArrayRelativeToSeg;
}

- (void)setImageView:(UIImageView *)imageView viewSize:(CGSize)viewSize placeholderImage:(UIImage *)placeholderImage withIndex:(NSInteger)index
{
    [imageView accCancelThumbnailRequests];
    
    CGSize size = viewSize;
    CGFloat longerEdge = size.width < size.height ? size.height : size.width;
    CGFloat screenScale = [UIScreen mainScreen].scale;
    size = CGSizeMake(longerEdge * screenScale, longerEdge * screenScale);
    
    CMTime time = self.allTimes[index].CMTimeValue;
    
    @weakify(imageView);
    ACCThumbnailRequest *request = [self.thumbnailCache
                                    getThumbnailForAsset:self.sourceAsset
                                    atTime:time
                                    preferedSize:size
                                    rotation:ACCVideoCompositionRotateTypeNone
                                    completion:^(UIImage *image) {
        @strongify(imageView);
        imageView.image = image;
    }];
    
    if (!request.fromCache) {
        imageView.image = placeholderImage;
        [imageView setAccThumbnailRequest:request];
    }
}

@end
