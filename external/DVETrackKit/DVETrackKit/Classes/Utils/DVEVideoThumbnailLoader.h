//
//  DVEVideoThumbnailLoader.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/21.
//

#import <Foundation/Foundation.h>
#import <NLEPlatform/NLEModel+iOS.h>
#import "DVEMediaContext.h"
#import "DVEVideoTrackThumbnail.h"

typedef void(^DVEThumbnailCompletionHandler)(UIImage *_Nullable image, NSError *_Nullable error, CMTime time);

NS_ASSUME_NONNULL_BEGIN

@interface DVEVideoThumbnailLoader : NSObject
// 抽帧的张数
@property (nonatomic, assign) NSInteger count;

- (instancetype)initWithContext:(DVEMediaContext *)context slot:(NLETrackSlot_OC *)slot;

- (nullable UIImage *)getImageForKey:(NSString *)key;

- (void)imageOfThumbnail:(DVEVideoTrackThumbnail *)thumbnail
              completion:(DVEThumbnailCompletionHandler)completion;

- (void)cancelAllTasks;

- (DVEVideoTrackThumbnail * _Nullable)thumbnailAtIndex:(NSInteger)index;

- (NSArray<DVEVideoTrackThumbnail *> *)thumbnailsOfSpeed:(CGFloat)speed scale:(CGFloat)scale;

- (DVEVideoTrackThumbnail * _Nullable)closestThumbnailInCache:(DVEVideoTrackThumbnail *)thumbnail;

- (NSString *)pathForThumbnail:(DVEVideoTrackThumbnail *)thumbnail;

- (NSOperation *)taskOfThumbnail:(DVEVideoTrackThumbnail *)thumbnail
                      completion:(DVEThumbnailCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
