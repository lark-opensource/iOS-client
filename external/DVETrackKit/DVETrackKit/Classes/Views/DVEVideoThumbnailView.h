//
//  DVEVideoThumbnailView.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/27.
//

#import <UIKit/UIKit.h>
#import "DVEVideoThumbnailCell.h"
#import "DVEVideoThumbnailLayout.h"
#import <NLEPlatform/NLEModel+iOS.h>

NS_ASSUME_NONNULL_BEGIN

@class DVEVideoThumbnailView;
@protocol DVEVideoThumbnailViewDelegate <NSObject>

- (void)videoThumbnailView:(DVEVideoThumbnailView *)videoThumbnailView didEndDisplayingCell:(DVEVideoThumbnailCell *)cell atIndex:(NSInteger)index;

@end


@protocol DVEVideoThumbnailViewDataSource <NSObject>

/**
 返回对index下的cell
 */
- (DVEVideoThumbnailCell * _Nullable)videoThumbnailView:(DVEVideoThumbnailView *)videoThumbnailView cellForItemAtIndex:(NSInteger)index;

/**
 总数量
 */
- (NSInteger)numberOfItems:(DVEVideoThumbnailView *)videoThumbnailView;

/**
 展示的item的下标集合
 */
- (NSRange)indexesForDisplayedItems:(DVEVideoThumbnailView *)videoThumbnailView;

@end

@interface DVEVideoThumbnailView : UIView

@property (nonatomic, weak) id<DVEVideoThumbnailViewDataSource> dataSource;
@property (nonatomic, weak) id<DVEVideoThumbnailViewDelegate> delegate;
@property (nonatomic, strong) DVEVideoThumbnailLayout *layout;
@property (nonatomic, strong) NLETrackSlot_OC *slot;

- (instancetype)initWithSlot:(NLETrackSlot_OC *)slot layout:(DVEVideoThumbnailLayout *)layout;

- (void)reloadDataWithForce:(BOOL)force;

- (DVEVideoThumbnailCell *)dequeueReusableCellForIndex:(NSInteger)index;

- (DVEVideoThumbnailCell *)cellForItemAtIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
