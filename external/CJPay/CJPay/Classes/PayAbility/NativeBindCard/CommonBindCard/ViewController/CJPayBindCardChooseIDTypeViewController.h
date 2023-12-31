//
//  CJPayBindCardChooseIDTypeViewController.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/14.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayBindCardChooseIDTypeCell.h"

NS_ASSUME_NONNULL_BEGIN


@protocol CJPayBindCardChooseIDTypeDelegate <NSObject>
    
- (void)didSelectIDType:(CJPayBindCardChooseIDType)idType;

@end


@interface CJPayBindCardChooseIDTypeViewController : CJPayHalfPageBaseViewController

@property (nonatomic,assign) CJPayBindCardChooseIDType selectedType;
@property (nonatomic,weak) id<CJPayBindCardChooseIDTypeDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
