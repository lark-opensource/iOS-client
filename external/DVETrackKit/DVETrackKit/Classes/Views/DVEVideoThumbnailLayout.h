//
//  DVEVideoThumbnailLayout.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class DVEVideoThumbnailView;
@class DVEVideoThumbnailLayout;
@protocol DVEVideoThumbnailLayoutDelegate <NSObject>

- (CGRect)videoThumbnailView:(DVEVideoThumbnailView *)videoThumbnailView layout:(DVEVideoThumbnailLayout *)layout rectForItemAtIndex:(NSInteger)index;

@end

@interface DVEVideoThumbnailLayout : NSObject

@property (nonatomic, weak, nullable) DVEVideoThumbnailView *videoThumbnailView;
@property (nonatomic, weak, nullable) id<DVEVideoThumbnailLayoutDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
