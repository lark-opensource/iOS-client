//
//  BDPayRechargeMethodView.h
//  CJPay
//
//  Created by 王新华 on 3/10/20.
//

#import <UIKit/UIKit.h>
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayUIMacro.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayChooseMethodView : UIView<CJPayBaseLoadingProtocol>

@property (nonatomic, copy) void(^clickBlock)(void);

@property (nonatomic, strong) CJPayDefaultChannelShowConfig *selectConfig;
@property (nonatomic, assign) CJPayComeFromSceneType comeFromSceneType;
@property (nonatomic, assign) NSInteger cardNum;
@property (nonatomic, assign) CJPayComeFromSceneType sceneType;

- (void)updateWithDefaultDiscount:(NSString *)discountStr;

@end

NS_ASSUME_NONNULL_END
