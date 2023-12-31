//
// Created by 张海阳 on 2020/2/20.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import "CJPayBaseResponse.h"

@class CJPayProcessInfo;
@class CJPayErrorButtonInfo;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCashDeskSendSMSResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *mobileMask;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@end

NS_ASSUME_NONNULL_END
