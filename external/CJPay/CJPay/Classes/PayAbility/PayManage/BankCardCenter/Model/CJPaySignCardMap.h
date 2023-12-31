//
//  CJPaySignCardMap.h
//  Pods
//
//  Created by wangxiaohong on 2020/10/25.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayQuickBindCardModel;

@interface CJPaySignCardMap : JSONModel

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;

@property (nonatomic, copy) NSString *allowTransCardType;
@property (nonatomic, copy) NSString *idNameMask;
@property (nonatomic, copy) NSString *idType;
@property (nonatomic, copy) NSString *isAuthed;
@property (nonatomic, copy) NSString *isSetPwd;
@property (nonatomic, copy) NSString *mobileMask;
@property (nonatomic, copy) NSString *skipPwd;
@property (nonatomic, copy) NSString *smchId;
@property (nonatomic, copy) NSString *uidMobileMask;
@property (nonatomic, copy) NSString *payUID;
@property (nonatomic, copy) NSString *memberBizOrderNo;

// 绑卡转化相关
@property (nonatomic, copy) NSString* jumpQuickBindCard;
@property (nonatomic, strong) CJPayQuickBindCardModel *quickCardModel;
@property (nonatomic, copy) NSString *displayIcon;
@property (nonatomic, copy) NSString *displayDesc;

@property (nonatomic, copy) NSString *protocolDescription;
@property (nonatomic, copy) NSString *buttonDescription;

@end

NS_ASSUME_NONNULL_END
