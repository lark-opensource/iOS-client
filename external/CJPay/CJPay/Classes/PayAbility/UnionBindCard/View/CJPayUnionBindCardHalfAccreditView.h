//
//  CJPayUnionBindCardHalfAccreditView.h
//  Pods
//
//  Created by chenbocheng on 2021/9/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayStyleButton;
@class CJPayUnionBindCardAuthorizationResponse;
@class CJPayCommonProtocolView;
@interface CJPayUnionBindCardHalfAccreditView : UIView

@property (nonatomic, strong, readonly) CJPayStyleButton *confirmButton;
@property (nonatomic, strong, readonly) CJPayCommonProtocolView *protocolView;
@property (nonatomic, copy) void(^protocolClickBlock)(void);

- (instancetype)initWithResponse:(CJPayUnionBindCardAuthorizationResponse *)response;

@end

NS_ASSUME_NONNULL_END
