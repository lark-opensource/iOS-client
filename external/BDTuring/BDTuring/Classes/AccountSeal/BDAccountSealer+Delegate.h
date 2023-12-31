//
//  BDAccountSealer+Delegate.h
//  BDTuring
//
//  Created by bob on 2020/7/15.
//

#import "BDAccountSealer.h"
#import "BDTuringWebView.h"
#import "BDTuringPiperConstant.h"

NS_ASSUME_NONNULL_BEGIN

@class BDAccountSealEvent;

@interface BDAccountSealer (Delegate)<BDTuringWebViewDelegate>

@property (nonatomic, strong) BDAccountSealEvent *eventService;

@end

NS_ASSUME_NONNULL_END
