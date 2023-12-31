//
//  CJPayGuideWithConfirmView.h
//  Pods
//
//  Created by chenbocheng on 2022/3/31.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayCommonProtocolView;
@class CJPayStyleButton;
@class CJPayCommonProtocolModel;
@interface CJPayGuideWithConfirmView : UIView

@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;
@property (nonatomic, strong, readonly) UIView *clickView;

- (instancetype)initWithCommonProtocolModel:(CJPayCommonProtocolModel *)protocolModel isShowButton:(BOOL)isShowButton;
- (void)updateProtocolModel:(CJPayCommonProtocolModel *)protocolModel isShowButton:(BOOL)isShowButton;

@end

NS_ASSUME_NONNULL_END
