//
//  CJPayBankCardItemViewModel.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayBaseListViewModel.h"
#import "CJPayBankCardModel.h"
#import "CJPayMemAuthInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBankCardItemViewModel : CJPayBaseListViewModel

@property (nonatomic,strong) CJPayBankCardModel *cardModel;
@property (nonatomic,strong) CJPayMemAuthInfo *authInfo;
@property (nonatomic,copy) NSString *merhcantId;
@property (nonatomic,copy) NSString *appId;
@property (nonatomic,copy) NSString *smchId;
@property (nonatomic,assign) BOOL canJumpCardDetail;
@property (nonatomic,assign) BOOL needShowUnbind;
@property (nonatomic, copy) NSDictionary *trackDic;
@property (nonatomic, copy) NSString *unbindUrl;

@property (nonatomic, assign) BOOL isSmallStyle; //是否是小卡片样式

@end

NS_ASSUME_NONNULL_END
