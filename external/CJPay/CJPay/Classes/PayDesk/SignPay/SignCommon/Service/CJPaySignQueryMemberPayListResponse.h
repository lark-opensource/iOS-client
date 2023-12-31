//
//  CJPaySignQueryMemberPayListResponse.h
//  Pods
//
//  Created by wangxiaohong on 2022/9/8.
//

#import "CJPayBaseResponse.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayChannelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface QueryMemberPayTypeItem : CJPayChannelModel

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *payMode;
@property (nonatomic, copy) NSString *cardNoMask;
@property (nonatomic, copy) NSString *bankCardId;
@property (nonatomic, copy) NSString *cardType;
@property (nonatomic, copy) NSString *notSupportMsg;

@end

@protocol QueryMemberPayTypeItem;
@interface CJPaySignQueryMemberPayListResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *payType;
@property (nonatomic, copy) NSArray<QueryMemberPayTypeItem> *payTypeList;
@property (nonatomic, strong) QueryMemberPayTypeItem *firstPayTypeItem;
@property (nonatomic, copy) NSString *displayName;

- (NSArray<CJPayDefaultChannelShowConfig *> *)memberPayListShowConfigs;

@end

NS_ASSUME_NONNULL_END
