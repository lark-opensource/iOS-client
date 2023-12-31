//
//  CJPayCardAddLoginProvider.h
//  Pods
//
//  Created by 王新华 on 2021/6/15.
//

#import <UIKit/UIKit.h>
#import "CJUniversalLoginManager.h"
#import "CJPayBankCardAddResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCardAddLoginProvider : NSObject<CJUniversalLoginProviderDelegate>

@property (nonatomic, copy) NSString *sourceName;
@property (nonatomic, strong) CJPayBankCardAddResponse *cardAddResponse;
@property (nonatomic, copy) void(^eventBlock)(int event);

- (instancetype)initWithBizParams:(NSDictionary *)bizParams userInfo:(CJPayUserInfo *)userInfo;

@end

NS_ASSUME_NONNULL_END
