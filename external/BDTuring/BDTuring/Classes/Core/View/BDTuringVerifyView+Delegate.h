//
//  BDTuringVerifyView+Delegate.h
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringVerifyView (Delegate)<UIScrollViewDelegate, WKNavigationDelegate>

- (void)cleanDelegates;

@end

NS_ASSUME_NONNULL_END
