//
//  CJPayProtocolViewManager.h
//  Pods
//
//  Created by wangxiaohong on 2020/10/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayMemAgreementModel;
@class CJPayMemProtocolListResponse;
@class CJPayHalfPageBaseViewController;
@class CJPayQuickPayUserAgreement;
@class CJPayCommonProtocolModel;

@interface CJPayProtocolViewManager : NSObject

+ (void)fetchProtocolListWithParams:(NSDictionary *)params
                         completion:(void (^)(NSError * _Nonnull, CJPayMemProtocolListResponse * _Nonnull))completion;

+ (CJPayHalfPageBaseViewController *)createProtocolViewController:(NSArray<CJPayQuickPayUserAgreement *> *)quickAgreeList protocolModel:(CJPayCommonProtocolModel *)protocolModel;

@end

NS_ASSUME_NONNULL_END
