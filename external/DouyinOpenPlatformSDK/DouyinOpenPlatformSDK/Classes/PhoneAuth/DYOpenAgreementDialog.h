//
//  DYOpenAgreementDialog.h
//  DouyinOpenPlatformSDK-ad006023
//
//  Created by AnchorCat on 2022/11/17.
//

#import "DYOpenBasePopupView.h"

NS_ASSUME_NONNULL_BEGIN

@interface DYOpenAgreementDialog : UIViewController

typedef void(^DYOpenAgreementOnClickAgree)(void);
typedef void(^DYOpenAgreementOnClickRefuse)(void);

@property (nonatomic, strong)DYOpenAgreementOnClickAgree onClickAgree;
@property (nonatomic, strong)DYOpenAgreementOnClickRefuse onClickRefuse;

- (instancetype)initWithData:(NSDictionary *)data;

@end

NS_ASSUME_NONNULL_END
