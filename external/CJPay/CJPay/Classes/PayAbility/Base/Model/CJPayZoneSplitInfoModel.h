//
//  CJPayZoneSplitInfoModel.h
//  cjpayBankLock
//
//  Created by shanghuaijun on 2023/2/15.
//

#import <JSONModel/JSONModel.h>


NS_ASSUME_NONNULL_BEGIN
@class CJPaySubPayTypeInfoModel;
@interface CJPayZoneSplitInfoModel : JSONModel

@property (nonatomic, assign) NSInteger zoneIndex;
@property (nonatomic, copy) NSString *zoneTitle;
@property (nonatomic, copy) NSString *combineZoneTitle;
@property (nonatomic, strong) CJPaySubPayTypeInfoModel *otherCardInfo;
@property (nonatomic, assign) BOOL isShowCombineTitle;

@end

NS_ASSUME_NONNULL_END
