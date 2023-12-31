//
//  ACCEditImageAlbumMixedProtocolD.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/7/5.
//

#import <Foundation/Foundation.h>
#import <CreationKitRTProtocol/ACCEditImageAlbumMixedProtocol.h>
#import "ACCImageAlbumEditorDefine.h"
#import <CreativeKit/ACCProtocolContainer.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditImageAlbumMixedMessageProtocolD <ACCEditImageAlbumMixedMessageProtocol>

@optional
/// scroll to index by auto timer or call "scroll to index"
- (void)onImagePlayerWillScrollToIndex:(NSInteger)targetIndex
                         withAnimation:(BOOL)withAnimation
                         isByAutoTimer:(BOOL)isByAutoTimer;

- (void)onCurrentImageEditorChanged:(NSInteger)currentIndex isByAutoTimer:(BOOL)isByAutoTimer;

- (void)onPlayerDraggingStatusChanged:(BOOL)isDragging;

@end

/// ACCEditImageAlbumMixedProtocol for D
/// @discussion 图集T不支持，是否整个移过来？
@protocol ACCEditImageAlbumMixedProtocolD <ACCEditImageAlbumMixedProtocol>

- (void)addSubscriber:(id<ACCEditImageAlbumMixedMessageProtocolD>)subscriber;

- (void)removeSubscriber:(id<ACCEditImageAlbumMixedMessageProtocolD>)subscriber;

#pragma mark - data control
/// 图集数据更新后可以reload，不会更改当前index(数据数量减少除外)
- (void)reloadData;

/// 跳转到指定index，会触发onImagePlayerWillScrollToIndex:回调
- (void)scrollToIndex:(NSInteger)index;

/// 标记当前图片需要刷新
- (void)markCurrentImageNeedReload;

#pragma mark - auto play
/// 总开关，用于AB开关，开关关闭后 start auto play相关接口都会屏蔽, 避免每次调用都做AB判断
@property (nonatomic, assign) BOOL enableAutoPlay;

@property (nonatomic, assign, readonly) BOOL isAutoPlaying;

- (void)setAutoPlayInterval:(NSTimeInterval)autoPlayInterval;

/// key类似于引用计数，当且仅当所有key都start后才会真正开始，比引用计数更保险一些，避免重复调用导致不匹配
- (void)startAutoPlayWithKey:(NSString *)key;

/// stop auto play and clear up current page's play  progress
- (void)stopAutoPlayWithKey:(NSString *)key;

#pragma mark - DIY
- (void)setPageControlStyle:(ACCImageAlbumEditorPageControlStyle)pageControlStyle;

// 进度条等交互区域的container，animationable
- (void)updateInteractionContainerAlpha:(CGFloat)alpha;

@end

NS_INLINE id<ACCEditImageAlbumMixedProtocolD> ACCImageAlbumMixedD(id<ACCEditImageAlbumMixedProtocol>imageAlbumMixed)
{
    if (!imageAlbumMixed) {
        return nil;
    }
    return ACCGetProtocol(imageAlbumMixed, ACCEditImageAlbumMixedProtocolD);
}

NS_ASSUME_NONNULL_END
