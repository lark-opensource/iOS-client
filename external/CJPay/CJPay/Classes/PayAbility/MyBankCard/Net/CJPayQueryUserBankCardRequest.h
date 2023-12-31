//
//  CJPayQueryUserBankCardRequest.h
//  BDPay
//
//  Created by 易培淮 on 2019/5/25.
//

#import "CJPayBaseRequest.h"
#import "CJPayBaseResponse.h"
#import "CJPayBankCardModel.h"
#import "CJPayMemAuthInfo.h"
#import "CJPayPassKitBizRequestModel.h"
#import "CJPayUserInfo.h"

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayBankCardModel;
@interface CJPayQueryUserBankCardRequestModel : JSONModel

@property (nonatomic, assign) BOOL isNeedQueryBankCardList;
@property (nonatomic, assign) BOOL isNeedQueryAuthInfo;
@property (nonatomic, assign) BOOL isNeedBindCardTopPageUrl;
@property (nonatomic, copy) NSString *source;

- (NSDictionary *)encryptDict;

@end


@interface BDPayQueryUserBankCardResponse : CJPayBaseResponse

@property(nonatomic, copy) NSString *authActionUrl;
@property(nonatomic, copy) NSArray<CJPayBankCardModel> *cardList;
@property(nonatomic, strong) CJPayMemAuthInfo *userInfo;
@property(nonatomic, assign) BOOL isAuthed;
@property(nonatomic, assign) BOOL isOpenAccount;
@property(nonatomic, assign) BOOL isSetPWD;
@property(nonatomic, assign) NSInteger memberLevel;
@property(nonatomic, assign) NSInteger memberType;
@property(nonatomic, copy) NSString *mobileMask;
@property(nonatomic, copy) NSString *payUID;
@property(nonatomic, assign) BOOL needAuthGuide;
@property(nonatomic, assign) BOOL needShowUnbind;
@property(nonatomic, copy) NSString *unbindUrl;
@property(nonatomic, copy) NSString *bindTopPageUrl;

- (CJPayUserInfo *)generateUserInfo;

@end

@interface CJPayQueryUserBankCardRequest : CJPayBaseRequest

+ (void)startWithModel:(CJPayQueryUserBankCardRequestModel *)requestModel
       bizRequestModel:(CJPayPassKitBizRequestModel *)bizRequestModel
            completion:(void(^)(NSError *error, BDPayQueryUserBankCardResponse *response))completion;

@end

NS_ASSUME_NONNULL_END
