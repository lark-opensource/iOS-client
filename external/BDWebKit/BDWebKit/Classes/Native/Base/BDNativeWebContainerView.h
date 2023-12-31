//
//  BDNativeWebContainerView.h
//  AFgzipRequestSerializer
//
//  Created by liuyunxuan on 2019/6/3.
//

#import <UIKit/UIKit.h>

typedef void(^BDNativeContainerBeRemovedAction)(void);

@interface BDNativeWebContainerView : UIView

- (void)configNativeContainerBeRemovedAction:(BDNativeContainerBeRemovedAction)action;

@end

