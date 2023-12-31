//
//  ByteViewRenderViewFactory.h
//  ByteViewRTCRenderer
//
//  Created by FakeGourmet on 2023/9/13.
//

#import <Foundation/Foundation.h>
#import "ByteViewRendererInterface.h"
#import "ByteViewRenderView.h"

NS_ASSUME_NONNULL_BEGIN

@class ByteViewRenderTicker;

@interface ByteViewRenderViewFactory : NSObject

- (instancetype)initWithRenderType: (ByteViewRendererType)type NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (ByteViewRenderView*)createWithRenderTicker:(ByteViewRenderTicker *__nullable)renderTicker
                                      fpsHint:(NSInteger)fps;
@end

NS_ASSUME_NONNULL_END
