//
//  BDTuring+Delegate.m
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuring+Delegate.h"
#import "BDTuring+Private.h"
#import "BDTuringVerifyView.h"
#import "BDTuringEventService.h"
#import "BDTuringUIHelper.h"

@implementation BDTuring (Delegate)


#pragma mark - BDTuringVerifyViewDelegate

- (void)verifyViewDidHide:(BDTuringVerifyView *)verifyView {
    self.isShowVerifyView = NO;
    __strong typeof(self) sself = self;
    __strong typeof(self.delegate) delegate = self.delegate;
    
    if ([delegate respondsToSelector:@selector(turingDidHide:)]) {
        [delegate turingDidHide:sself];
    }
    
    self.verifyView = nil;
}

- (void)verifyViewDidShow:(BDTuringVerifyView *)verifyView {
    __strong typeof(self) sself = self;
    __strong typeof(self.delegate) delegate = self.delegate;
    
    if ([delegate respondsToSelector:@selector(turingDidShow:)]) {
        [delegate turingDidShow:sself];
    }
    
}

- (void)verifyWebViewLoadDidSuccess:(BDTuringVerifyView *)verifyView {
    __strong typeof(self) sself = self;
    __strong typeof(self.delegate) delegate = self.delegate;
    
    if (![verifyView isShow] && ![verifyView isPreloadVerifyView]) {
        [verifyView showVerifyViewTillWebViewReady];
    }
    
    if ([delegate respondsToSelector:@selector(turingWebViewDidLoadSuccess:)]) {
        [delegate turingWebViewDidLoadSuccess:sself];
    }
}

- (void)verifyWebViewLoadDidFail:(BDTuringVerifyView *)verifyView {
    __strong typeof(self) sself = self;
    __strong typeof(self.delegate) delegate = self.delegate;
    
    if (![verifyView isShow]) {
        [verifyView showVerifyViewTillWebViewReady];
    }

    
    if ([delegate respondsToSelector:@selector(verifyWebViewDidLoadFail:)]) {
        [delegate verifyWebViewDidLoadFail:sself];
    }
}


@end
