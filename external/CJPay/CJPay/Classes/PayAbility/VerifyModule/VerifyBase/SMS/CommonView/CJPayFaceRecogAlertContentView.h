//
//  CJPayFaceRecogAlertContentView.h
//  CJPay
//
//  Created by 尚怀军 on 2020/8/19.
//

#import <UIKit/UIKit.h>
#import "CJPayFaceRecognitionModel.h"
#import "CJPayTrackerProtocol.h"

@class CJPayCommonProtocolModel;
@class CJPayMemAgreementModel;
@class CJPayCommonProtocolView;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayFaceRecogAlertContentView : UIView

@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;
@property (nonatomic, weak) id<CJPayTrackerProtocol> trackDelegate;

- (instancetype)initWithProtocolModel:(CJPayCommonProtocolModel *)protocolModel
                             showType:(CJPayFaceRecognitionStyle)type
               shouldShowProtocolView:(BOOL)shouldShowProtocolView
                     protocolDidClick:(void(^)(NSArray<CJPayMemAgreementModel *> *agreements, UIViewController *topVC))protocolDidClick;

- (void)updateWithTitle:(NSString *)title;

+ (NSDictionary *)attributes;
+ (NSDictionary *)attributesWithForegroundColor:(nullable UIColor *)foregroundColor alignment:(NSTextAlignment)alignment;
+ (UIColor *)highlightColor;

@end

NS_ASSUME_NONNULL_END
