//
//  ByteViewSampleBufferLayerView.m
//  ByteViewRTCRenderer
//
//  Created by FakeGourmet on 2023/9/12.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import "ByteViewSampleBufferLayerView.h"
#import "ByteViewSampleBufferReceiver.h"
#import "ByteViewRenderView+Initialize.h"

@implementation ByteViewSampleBufferLayerView

- (instancetype)_initWithFrame:(CGRect)frame {
    if (self = [super _initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    ByteViewSampleBufferLayerReceiver *receiver = [[ByteViewSampleBufferLayerReceiver alloc] init];
    receiver.parent = self;
    self.frameReceiver = receiver;
    AVSampleBufferDisplayLayer* sampleBufferLayer = (AVSampleBufferDisplayLayer*)[self layer];
    if (sampleBufferLayer) {
        [sampleBufferLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    }
}

+ (Class)layerClass {
    return [AVSampleBufferDisplayLayer class];
}

@end
