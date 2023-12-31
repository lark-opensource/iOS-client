//
//  CJPayQueryOneKeySignResponse.h
//  Pods
//
//  Created by 王新华 on 2020/10/14.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayErrorButtonInfo;
@interface CJPayQueryOneKeySignResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *orderStatus;
@property (nonatomic, copy) NSString *signNo;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *bankCardId;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@end

NS_ASSUME_NONNULL_END
