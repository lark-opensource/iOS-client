//
//  BytedCertWaitingView.h
//  AFgzipRequestSerializer
//
//  Created by xunianqiang on 2020/3/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface BDCTWaitingView : UIView

@property (nonatomic, strong) UIImageView *imageView;

- (void)startAnimating;
- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
