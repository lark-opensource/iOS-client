//
//  CJPayProtocolPopUpViewController.h
//  Pods
//
//  Created by 徐天喜 on 2022/8/02.
//

#import "CJPayPopUpBaseViewController.h"

@class CJPayCommonProtocolModel;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayProtocolPopUpViewController : CJPayPopUpBaseViewController

@property (nonatomic, copy) void(^confirmBlock)(void);
@property (nonatomic, copy) void(^cancelBlock)(void);
@property (nonatomic, assign) BOOL showFullPageProtocolView;

- (instancetype)initWithProtocolModel:(CJPayCommonProtocolModel *)model from:(NSString *)fromPage;

@end

NS_ASSUME_NONNULL_END
