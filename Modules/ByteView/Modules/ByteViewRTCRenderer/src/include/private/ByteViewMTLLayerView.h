//
//  ByteViewMTLLayerView.h
//  ByteViewRTCRenderer
//
//  Created by liujianlong on 2022/7/28.
//

#import "ByteViewRenderView.h"

NS_ASSUME_NONNULL_BEGIN

@class ByteViewRenderTicker;

@interface ByteViewMTLLayerView : ByteViewRenderView

- (instancetype)initWithRenderTicker:(ByteViewRenderTicker *)renderTicker fpsHint:(NSInteger)fps;

@end

NS_ASSUME_NONNULL_END
