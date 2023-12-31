//
//  BDTuringVerifyView+Loading.h
//  BDTuring
//
//  Created by bob on 2020/7/22.
//

#import "BDTuringVerifyView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringVerifyView (Loading)

@property (nonatomic, strong, nullable) UIActivityIndicatorView *indicatorView;

- (void)startLoadingView;
- (void)stopLoadingView;

@end

NS_ASSUME_NONNULL_END
