//
//  DYOpenUILoading.h
//  AWEUIKit
//
//  Created by 熊典 on 2018/7/11.
//

#import <UIKit/UIKit.h>
#import "DYOpenUILoadingView.h"

@protocol DYOpenUILoadingProvider <NSObject>

- (UIView * _Nullable)loadingViewContainerView;

@end

@interface DYOpenUILoading : NSObject

+ (DYOpenUILoadingView * _Nullable)showLoadingOnView:(UIView * _Nullable)view;
+ (DYOpenUILoadingView * _Nullable)showLoadingOnView:(UIView * _Nullable)view animated:(BOOL)animated;

@end


