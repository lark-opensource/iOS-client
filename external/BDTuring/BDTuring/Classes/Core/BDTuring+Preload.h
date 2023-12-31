//
//  BDTuring+Preload.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/9/3.
//

#import "BDTuring.h"

@class BDTuringVerifyView;

NS_ASSUME_NONNULL_BEGIN

@interface BDTuring (Preload)

- (void)preloadFinishWithVerifyView:(BDTuringVerifyView *)verifyView;

- (void)popPreloadVerifyView;

@end

NS_ASSUME_NONNULL_END
