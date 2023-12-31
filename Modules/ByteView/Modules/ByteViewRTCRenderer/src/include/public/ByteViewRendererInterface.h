//
//  ByteViewRendererInterface.h
//  ByteViewRTCRenderer
//
//  Created by liujianlong on 2021/6/10.
//

#ifndef ByteViewRendererInterface_h
#define ByteViewRendererInterface_h
#import "ByteViewVideoFrame.h"


NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ByteViewRendererType) {
    ByteViewRendererTypeMetalLayer = 0,
    ByteViewRendererTypeSampleBufferLayer = 1,
};

@protocol ByteViewVideoRenderer <NSObject>

/** The frame to be displayed. */
- (void)renderFrame:(nullable ByteViewVideoFrame *)videoFrame;

@end

typedef id<ByteViewVideoRenderer> ByteViewFrameReceiver;

@protocol ByteViewRenderElapseObserver <NSObject>

- (void)reportRenderElapse:(int)elapse;

@end

NS_ASSUME_NONNULL_END

#endif /* ByteViewRendererInterface_h */
