//
//  ByteViewRenderViewFactory.m
//  ByteViewRTCRenderer
//
//  Created by FakeGourmet on 2023/9/13.
//

#import <Foundation/Foundation.h>
#import "ByteViewRenderViewFactory.h"
#import "ByteViewRendererInterface.h"
#import "ByteViewMTLLayerView.h"
#import "ByteViewSampleBufferLayerView.h"
#import "ByteViewRenderView+Initialize.h"

@interface ByteViewRenderViewFactory ()

@property(nonatomic, assign) ByteViewRendererType type;

@end

@implementation ByteViewRenderViewFactory

- (nonnull instancetype)initWithRenderType:(ByteViewRendererType)type {
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}

- (ByteViewRenderView*)createWithRenderTicker:(id)renderTicker fpsHint:(NSInteger)fps {
    switch (self.type) {
        case ByteViewRendererTypeMetalLayer:
            return [[ByteViewMTLLayerView alloc] initWithRenderTicker:renderTicker fpsHint:fps];
        case ByteViewRendererTypeSampleBufferLayer:
            return [[ByteViewSampleBufferLayerView alloc] _initWithFrame:CGRectZero];
    }
}

@end
