//
//  CJPayBioConfirmHomeView.h
//  Pods
//
//  Created by wangxiaohong on 2020/11/15.
//

#import <UIKit/UIKit.h>
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayEnumUtil.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayStyleButton;
@interface CJPayBioConfirmHomeView : UIView

@property (nonatomic, strong, readonly) CJPayStyleButton *confirmButton;
@property (nonatomic, copy) void(^confirmButtonClickBlock)(void);
@property (nonatomic, copy) void(^trackerBlock)(NSString *, NSDictionary *);

- (void)updateUI:(CJPayBDCreateOrderResponse *) model;
- (BOOL)isCheckBoxSelected;

@end

NS_ASSUME_NONNULL_END
