//
//  DVEVideoThumbnailManager.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/22.
//

#import <Foundation/Foundation.h>
#import "DVEVideoThumbnailLoader.h"

NS_ASSUME_NONNULL_BEGIN

@class DVEMediaContext;
@class NLETrackSlot_OC;

@interface DVEVideoThumbnailManager : NSObject

- (instancetype)initWithContext:(DVEMediaContext *)context;

- (NSString *)loaderKeyForSlot:(NLETrackSlot_OC *)slot;

- (DVEVideoThumbnailLoader *)loaderForSlot:(NLETrackSlot_OC *)slot;

- (void)cleanSlot:(NLETrackSlot_OC *)slot;

- (NSArray<DVEVideoTrackThumbnail *> *)thumbnailOfSlot:(NLETrackSlot_OC *)slot;

- (DVEVideoTrackThumbnail *)thumbnailOfSlot:(NLETrackSlot_OC *)slot
                                      index:(NSInteger)index;

- (NSInteger)countOfSlot:(NLETrackSlot_OC *)slot;

- (DVEVideoTrackThumbnail *)getClosetThumbnailWithThumbnail:(DVEVideoTrackThumbnail *)thumbnail
                                                       slot:(NLETrackSlot_OC *)slot;


- (void)fetchAsyncWithThumbnail:(DVEVideoTrackThumbnail *)thumbnail
                           slot:(NLETrackSlot_OC *)slot
                     completion:(DVEThumbnailCompletionHandler)completion;

- (void)cancelWithThumbnail:(DVEVideoTrackThumbnail *)thumbnail
                       slot:(NLETrackSlot_OC *)slot;

@end

NS_ASSUME_NONNULL_END
