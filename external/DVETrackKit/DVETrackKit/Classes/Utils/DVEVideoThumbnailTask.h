//
//  DVEVideoThumbnailTask.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/22.
//

#import <Foundation/Foundation.h>
#import "DVEVideoThumbnailLoader.h"
#import "DVEVideoTrackThumbnail.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEVideoThumbnailTask : NSOperation

@property (nonatomic, strong, nullable) DVEVideoThumbnailLoader *loader;
@property (nonatomic, strong, nullable) DVEVideoTrackThumbnail *thumbnail;
@property (nonatomic, copy, nullable) DVEThumbnailCompletionHandler completion;

- (instancetype)initWithLoader:(DVEVideoThumbnailLoader *)loader
                     thumbnail:(DVEVideoTrackThumbnail *)thumbnail
                    completion:(DVEThumbnailCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
