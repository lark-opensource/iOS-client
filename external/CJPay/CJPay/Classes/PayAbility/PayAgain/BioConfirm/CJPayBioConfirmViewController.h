//
//  CJPayBioConfirmViewController.h
//  Pods
//
//  Created by wangxiaohong on 2020/11/13.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBioConfirmHomeView.h"

NS_ASSUME_NONNULL_BEGIN
@interface CJPayBioConfirmViewController : CJPayHalfPageBaseViewController

@property (nonatomic, strong, readonly) CJPayBioConfirmHomeView *homeView;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *model;

@property (nonatomic, copy) void(^confirmPayBlock)(BOOL);
@property (nonatomic, copy) void(^passCodePayBlock)(void);
@property (nonatomic, copy) void(^trackerBlock)(NSString *, NSDictionary *);

- (void)setConfirmButtonEnableStatus:(BOOL)isEnable;

@end

NS_ASSUME_NONNULL_END

