//
//  CJPayBizAuthInfoModel.h
//  Pods
//
//  Created by xiuyuanLee on 2020/11/2.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayMemAgreementModel;
@protocol CJPayMemAgreementModel;
@class CJPayAuthAgreementContentModel;
@interface CJPayBizAuthInfoModel : JSONModel

@property (nonatomic, assign) BOOL isNeedAuthorize;
@property (nonatomic, assign) BOOL isAuthed;
@property (nonatomic, assign) BOOL isConflict;
@property (nonatomic, copy) NSString *conflictActionURL;

@property (nonatomic, copy) NSString *idType;
@property (nonatomic, copy) NSString *idCodeMask;
@property (nonatomic, copy) NSString *idNameMask;

@property (nonatomic, strong) CJPayAuthAgreementContentModel *authAgreementContentModel;

@property (nonatomic, copy) NSString *guideMessage;
@property (nonatomic, copy) NSDictionary *protocolGroupNames;
@property (nonatomic, copy) NSArray<CJPayMemAgreementModel> *agreements;
@property (nonatomic, copy) NSString *protocolCheckBox;
- (NSString *)disagreeContent;
- (NSString *)tipsContent;

@end

NS_ASSUME_NONNULL_END
