//
//  BDTuring+Preload.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/9/3.
//

#import "BDTuring+Preload.h"
#import "BDTuring+Private.h"
#import "BDTuringVerifyView.h"
#import "BDTuringVerifyView+Piper.h"

@implementation BDTuring (Preload)

- (void)preloadFinishWithVerifyView:(BDTuringVerifyView *)verifyView {
    self.preloadVerifyView = verifyView;
    self.preloadVerifyViewReady = YES;
}

- (void)popPreloadVerifyView {
    self.verifyView = self.preloadVerifyView;
    self.preloadVerifyView = nil;
    self.preloadVerifyViewReady = NO;
    [self.verifyView refreshVerifyView];
    [self.verifyView showVerifyView];
}

@end
