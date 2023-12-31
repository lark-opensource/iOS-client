//
//  CJPayPreTradeInfo.h
//  Pods
//
//  Created by 王新华 on 2022/2/25.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN
@interface CJPayPreTradeTrackInfo : JSONModel

@property (nonatomic, copy) NSString *balanceStatus;
@property (nonatomic, copy) NSString *bankCardStatus;
@property (nonatomic, copy) NSString *creditStatus;

@end

@interface CJPayPreTradeInfo : JSONModel

@property (nonatomic, copy) NSString *bankCardID;
@property (nonatomic, copy) NSString *cardNoMask;
@property (nonatomic, copy) NSString *mobileMask;
@property (nonatomic, copy) NSString *bankName;
@property (nonatomic, copy) NSString *exts;
@property (nonatomic, strong) CJPayPreTradeTrackInfo *trackInfo;

@end

NS_ASSUME_NONNULL_END
