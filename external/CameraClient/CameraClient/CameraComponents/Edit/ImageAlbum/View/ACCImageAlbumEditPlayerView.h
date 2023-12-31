//
//  ACCImageAlbumEditPlayerView.h
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/14.
//

#import <UIKit/UIKit.h>
#import "ACCImageAlbumEditorDefine.h"
NS_ASSUME_NONNULL_BEGIN

@class ACCImageAlbumData;
@protocol ACCImageAlbumEditPlayerViewDataSource;
@protocol ACCImageAlbumEditPlayerViewDelegate;


@interface ACCImageAlbumEditPlayerView : UIView

@property (nonatomic, assign, readonly) NSInteger currentIndex;
@property (nonatomic, weak) id<ACCImageAlbumEditPlayerViewDataSource> dataSource;
@property (nonatomic, weak) id<ACCImageAlbumEditPlayerViewDelegate> delegate;
@property (nonatomic, assign) CGFloat bottomOffset;
@property (nonatomic, assign) ACCImageAlbumEditorPageControlStyle pageControlStyle ;
@property (nonatomic, assign) NSTimeInterval autoPlayInterval;
- (void)startAutoPlay;
- (void)stopAutoPlay;
@property (nonatomic, assign) BOOL scrollEnable; /// default is YES
- (BOOL)isDraggingOrScrolling;

- (void)reloadData;
- (void)scrollToIndex:(NSInteger)index;
// 进度条等交互区域的container，animationable
- (void)updateInteractionContainerAlpha:(CGFloat)alpha;

@end


@protocol  ACCImageAlbumEditPlayerViewDataSource<NSObject>

- (NSInteger)numberOfPreviewForAlbumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView;
- (UIView *)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView previewViewAtIndex:(NSInteger)index;
- (BOOL)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView hasPreloadedItemWithIndex:(NSInteger)index;

@end


@protocol  ACCImageAlbumEditPlayerViewDelegate<NSObject>

- (void)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView
      didUpdateCurrentIndex:(NSInteger)currentIndex
              isByAutoTimer:(BOOL)isByAutoTimer;

- (void)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView
     didUpdatePreloadIndexs:(NSArray <NSNumber *> *)preloadIndexs;

- (void)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerViewt
          willScrollToIndex:(NSInteger)targetIndex
              withAnimation:(BOOL)withAnimation
              isByAutoTimer:(BOOL)isByAutoTimer;

- (void)albumEditPlayerView:(ACCImageAlbumEditPlayerView *)playerView
        didUpdateDraggingStatus:(BOOL)isDrag;

- (void)albumEditPlayerViewDidEndAnimationAndDragging:(ACCImageAlbumEditPlayerView *)playerView;
        

@end

NS_ASSUME_NONNULL_END
