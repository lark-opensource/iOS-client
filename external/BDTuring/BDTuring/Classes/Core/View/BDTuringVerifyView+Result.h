//
//  BDTuringVerifyView+Result.h
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringVerifyView (Result)

- (void)handleCallbackStatus:(BDTuringVerifyStatus)status;
- (void)handleCallbackResult:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
