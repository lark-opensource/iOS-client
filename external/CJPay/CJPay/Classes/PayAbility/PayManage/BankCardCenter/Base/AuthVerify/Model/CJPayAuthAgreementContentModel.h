//
//  CJPayAuthAgreementContentModel.h
//  CJPay
//
//  Created by wangxiaohong on 2020/5/25.
//

#import <JSONModel/JSONModel.h>

#import "CJPayAuthDisplayContentModel.h"
#import "CJPayAuthDisplayMultiContentModel.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayAuthDisplayContentModel;
@protocol CJPayAuthDisplayMultiContentModel;
@interface CJPayAuthAgreementContentModel : JSONModel

@property (nonatomic, strong) CJPayAuthDisplayContentModel *businessBriefInfo;
@property (nonatomic, copy) NSString *proposeDesc;
@property (nonatomic, copy) NSArray<NSString *> *proposeContents;
@property (nonatomic, copy) NSArray<CJPayAuthDisplayContentModel> *agreementContents;
@property (nonatomic, copy) NSArray<CJPayAuthDisplayMultiContentModel> *secondAgreementContents;
@property (nonatomic, copy) NSString *disagreeUrl;
@property (nonatomic, copy) NSString *disagreeContent;
@property (nonatomic, copy) NSString *tipsContent;
@property (nonatomic, assign) NSInteger authorizeItem;

@end

NS_ASSUME_NONNULL_END
