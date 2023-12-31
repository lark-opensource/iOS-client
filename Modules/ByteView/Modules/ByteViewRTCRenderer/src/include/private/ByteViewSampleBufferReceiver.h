//
//  ByteViewSampleBufferReceiver.h
//  ByteViewRTCRenderer
//
//  Created by FakeGourmet on 2023/9/14.
//

#import <Foundation/Foundation.h>
#import "ByteViewRendererInterface.h"
#import "ByteViewSampleBufferLayerView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ByteViewSampleBufferLayerReceiver : NSObject <ByteViewVideoRenderer>

@property(weak, nonatomic) ByteViewSampleBufferLayerView *parent;

@end

NS_ASSUME_NONNULL_END
