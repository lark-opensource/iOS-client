//
//  ByteViewRenderView.h
//  ByteViewRTCRenderer
//
//  Created by FakeGourmet on 2023/9/12.
//

#import "ByteViewRendererInterface.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ByteViewRenderView : UIView

@property(strong, nonatomic, nullable) ByteViewFrameReceiver frameReceiver;

@property(weak, nonatomic) id<ByteViewRenderElapseObserver> renderElapseObserver;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
