//
//  CJPaySignCardVerifySMSViewController.h
//  Pods
//
//  Created by 尚怀军 on 2020/12/30.
//

#import "CJPayVerifySMSViewController.h"
#import "CJPayCardManageModule.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayCreateOneKeySignOrderResponse;
@class CJPaySignSMSResponse;
@interface CJPaySignCardVerifySMSViewController : CJPayVerifySMSViewController

@property (nonatomic, strong) CJPayCreateOneKeySignOrderResponse *oneKeyOrderResponse;
@property (nonatomic, assign) CJPayCardBindSourceType cardBindSource;
@property (nonatomic, copy) NSDictionary *extTrackParam;
@property (nonatomic, copy) void(^signCardSuccessBlock)(CJPaySignSMSResponse *);

- (instancetype)initWithSchemaParams:(NSDictionary *)schemaParams;

@end

NS_ASSUME_NONNULL_END
