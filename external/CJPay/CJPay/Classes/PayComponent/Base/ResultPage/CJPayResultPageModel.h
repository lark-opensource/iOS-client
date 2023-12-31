//
//  CJPayResultPageModel.h
//  CJPaySandBox
//
//  Created by liutianyi on 2023/3/9.
//

#import "CJPayResultPageModel.h"
#import "CJPaySDKDefine.h"
#import "CJPayResultPageInfoModel.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN
@protocol CJPayPaymentInfo;
@interface CJPayResultPageModel : JSONModel

@property (nonatomic, assign) int64_t remainTime;
@property (nonatomic, strong) CJPayResultPageInfoModel *resultPageInfo;
@property (nonatomic, copy) NSString *openSchema;
@property (nonatomic, copy) NSString *openUrl;
@property (nonatomic, copy) NSDictionary *orderResponse;

@property (nonatomic, copy) NSString *orderType;
@property (nonatomic, assign) NSInteger amount;

@end

NS_ASSUME_NONNULL_END
