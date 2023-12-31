//
//  BDTuringVerifyModel+View.h
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDTuringVerifyModel.h"

NS_ASSUME_NONNULL_BEGIN

@class BDTuringVerifyView;


@interface BDTuringVerifyModel (View)

- (BDTuringVerifyView *)createVerifyView;
- (void)configVerifyView:(BDTuringVerifyView *)verifyView;
- (void)loadVerifyView:(BDTuringVerifyView *)verifyView;


@end

NS_ASSUME_NONNULL_END
