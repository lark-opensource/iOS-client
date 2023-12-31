//
//  CJPaySuggestAddCardView.h
//  CJPaySandBox
//
//  Created by xutianxi on 2023/5/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayChannelBizModel;

typedef NS_ENUM(NSUInteger, CJPaySuggestAddCardViewStyle) {
    CJPaySuggestAddCardViewStyleWithoutSuggestCard = 0,
    CJPaySuggestAddCardViewStyleWithSuggestCard,
};

@interface CJPaySuggestAddCardView : UIView

@property (nonatomic, copy) void(^didClickedMoreBankBlock)(void);
@property (nonatomic, copy) void(^didSelectedNewSuggestBankBlock)(int index);
@property (nonatomic, strong, readonly) UILabel *moreBankTipsLabel;

- (instancetype)initWithStyle:(CJPaySuggestAddCardViewStyle)style;
- (void)updateContent:(NSArray <CJPayChannelBizModel *> *)modelArray;

@end

NS_ASSUME_NONNULL_END
