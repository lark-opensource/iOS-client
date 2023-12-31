//
//  CJPayLoadingButton.h
//  CJPay
//
//  Created by liyu on 2019/10/29.
//

#import "CJPayButton.h"
#import "CJPayEnumUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayLoadingButton : CJPayButton <CJPayBaseLoadingProtocol>

@property (nonatomic, assign) BOOL disablesInteractionWhenLoading;

- (void)startLoadingWithWindowEnable:(BOOL)windowEnable;
- (void)startLeftLoading;
- (void)startRightLoading;
- (void)stopLeftLoading;
- (void)stopRightLoading;
- (void)stopLoadingWithTitle:(NSString*)title;
- (void)stopRightLoadingWithTitle:(NSString *)title;

@end

NS_ASSUME_NONNULL_END
