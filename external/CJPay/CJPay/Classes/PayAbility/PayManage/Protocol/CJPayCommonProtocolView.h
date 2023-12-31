//
//  CJPayCommonProtocolView.h
//  Pods
//
//  Created by 尚怀军 on 2021/3/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayCommonProtocolModel;
@class CJPayMemAgreementModel;
@class CJPaySwitch;

@interface CJPayCommonProtocolView : UIView

@property (nonatomic, copy) void(^protocolClickBlock)(NSArray<CJPayMemAgreementModel *> *agreements);
@property (nonatomic, copy) void(^checkBoxClickBlock)(void);
@property (nonatomic, assign) BOOL protocolClickHandleInBlockOnly;
@property (nonatomic, strong, readonly) CJPayCommonProtocolModel *protocolModel;

- (instancetype)initWithCommonProtocolModel:(CJPayCommonProtocolModel *)protocolModel;
- (BOOL)isCheckBoxSelected;
- (void)setCheckBoxSelected:(BOOL)isSelected;
- (void)updateWithCommonModel:(CJPayCommonProtocolModel *)commonModel;
- (void)executeWhenProtocolSelected:(void(^)(void))actionBlock;
- (void)executeWhenProtocolSelected:(void(^)(void))actionBlock
                         notSeleted:(nullable void(^)(void))notSeletedBlock
                           hasToast:(BOOL)isToast;
- (void)setProtocolDetailContainerHeight:(CGFloat)viewHeight;//设置协议内容页面高度
- (void)agreeCheckBoxTapped; // checkbox或switch点击
- (nullable UIView *)getClickBtnView;
@end

NS_ASSUME_NONNULL_END
