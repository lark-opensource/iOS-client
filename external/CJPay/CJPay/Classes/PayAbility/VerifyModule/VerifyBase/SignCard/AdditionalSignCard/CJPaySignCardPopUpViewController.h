//
//  CJPaySignCardPopUpViewController.h
//  CJPaySandBox
//
//  Created by 王晓红 on 2023/7/26.
//

#import "CJPayPopUpBaseViewController.h"
#import "CJPaySignCardView.h"
#import "CJPaySignCardInfo.h"
#import "CJPayTrackerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySignCardPopUpViewController : CJPayPopUpBaseViewController

@property (nonatomic, strong, readonly) CJPaySignCardView *tipsView;
@property (nonatomic, weak) id<CJPayTrackerProtocol> trackDelegate;
@property (nonatomic, copy) void(^confirmButtonClickBlock)(CJPayStyleButton *confirmButton);
@property (nonatomic, copy) void(^closeButtonClickBlock)(void);
@property (nonatomic, copy) NSString *bankNameTitle;

- (instancetype)initWithSignCardInfoModel:(CJPaySignCardInfo *)signCardInfoModel;

@end

NS_ASSUME_NONNULL_END
