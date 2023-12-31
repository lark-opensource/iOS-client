//
//  BDASplashShakeGIFView.h
//  TTAdSplashSDK
//
//  Created by boolchow on 2021/1/11.
//

#import <UIKit/UIKit.h>
#import "BDASplashShakeContainerView.h"

@class TTAdSplashModel;
@class BDASplashView;

NS_ASSUME_NONNULL_BEGIN

/// 普通版摇一摇创意广告，第二段视图，即摇一摇动作触发之后，显示的第二段动图。
@interface BDASplashShakeGIFView : UIView

@property (nonatomic, weak) id<BDASplashShakeProtocol> delegate;

- (instancetype)initWithFrame:(CGRect)frame model:(TTAdSplashModel *)model targetView:(BDASplashView *)targetView;

@end

NS_ASSUME_NONNULL_END
