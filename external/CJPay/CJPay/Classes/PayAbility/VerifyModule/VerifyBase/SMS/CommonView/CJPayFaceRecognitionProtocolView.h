//
//  CJPayFaceRecognitionProtocolView.h
//  CJPay
//
//  Created by 尚怀军 on 2020/8/18.
//

#import <UIKit/UIKit.h>
#import "CJPayTrackerProtocol.h"
#import "CJPayStyleCheckBox.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayFaceRecognitionProtocolView : UIView

@property (nonatomic, strong, readonly) CJPayStyleCheckBox *checkBoxButton;
@property (nonatomic, assign) BOOL checkBoxIsSelect;
@property (nonatomic, copy) NSString *agreementName;
@property (nonatomic, copy) NSString *agreementURL;
@property (nonatomic, weak) id<CJPayTrackerProtocol> trackDelegate;

- (instancetype)initWithAgreementName:(NSString *)agreementName
                         agreementURL:(NSString *)agreementURL;

@end

NS_ASSUME_NONNULL_END
