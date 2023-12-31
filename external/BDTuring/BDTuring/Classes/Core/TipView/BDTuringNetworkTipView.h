//
//  BDTuringNetworkTipView.h
//  BDTuring
//
//  Created by bob on 2019/8/28.
//

#import <UIKit/UIKit.h>
#import "BDTuringVerifyView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringNetworkTipView : UIView

- (instancetype)initWithFrame:(CGRect)frame language:(NSString *)language target:(BDTuringVerifyView *)target;

@end

NS_ASSUME_NONNULL_END
