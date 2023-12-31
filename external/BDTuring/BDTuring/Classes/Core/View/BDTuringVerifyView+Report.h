//
//  BDTuringVerifyView+Report.h
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyView.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringPiperConstant.h"
#import "BDTuringEventConstant.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringVerifyView (Report)

- (void)handlePiperGetData:(NSDictionary *)params
                     callback:(BDTuringPiperOnCallback)callback;

- (void)handlePiperGetTouch:(NSDictionary *)params
                      callback:(BDTuringPiperOnCallback)callback;

- (void)handleNativeEventUpload:(NSDictionary *)event
                       callback:(BDTuringPiperOnCallback)callback;

- (void)handlePiperPageEnd:(NSDictionary *)params
                     callback:(BDTuringPiperOnCallback)callback;

- (void)handlePiperVerifyResult:(NSDictionary *)params;

- (void)onWebViewFinish;
- (void)onWebViewFailWithError:(NSError *)error;

- (void)closeEvent:(BDTuringEventCloseReason)reason;

@end

NS_ASSUME_NONNULL_END
