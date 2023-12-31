//
//  CJPayBindCardSetPasswordRetainInfo.h
//  CJPaySandBox
//
//  Created by wangxiaohong on 2022/11/22.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBindCardSetPasswordRetainInfo : JSONModel

@property (nonatomic, copy) NSString *isNeedRetain;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *buttonType;
@property (nonatomic, copy) NSString *buttonMsg;
@property (nonatomic, copy) NSString *buttonLeftMsg;
@property (nonatomic, copy) NSString *buttonRightMsg;

@end

NS_ASSUME_NONNULL_END
