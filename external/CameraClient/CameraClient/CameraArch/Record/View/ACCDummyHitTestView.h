//
//  ACCDummyHitTestView.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/10.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCDummyHitTestView : UIView

@property (nonatomic, copy, nullable) dispatch_block_t hitTestHandler;

@end

NS_ASSUME_NONNULL_END
