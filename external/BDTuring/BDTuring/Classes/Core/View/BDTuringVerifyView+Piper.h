//
//  BDTuringVerifyView+Piper.h
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringVerifyView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringVerifyView (Piper)

- (void)installPiper;

- (void)closeVerifyView:(NSString *)reason;

- (void)onOrientationChanged:(NSDictionary *)orientation;

- (void)refreshVerifyView;

@end

NS_ASSUME_NONNULL_END
