//
//  BytedCertPopView.h
//  Pods
//
//  Created by LiuChundian on 2019/9/25.
//

#ifndef BytedCertPopView_h
#define BytedCertPopView_h
#import <UIKit/UIKit.h>
#import "BDCTDisablePanGestureViewController.h"


@interface BDCTWebViewController : BDCTDisablePanGestureViewController

- (instancetype)initWithUrl:(NSString *)url title:(NSString *)title;

@end
#endif /* BytedCertPopView_h */
