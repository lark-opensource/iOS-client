//
//  CJPayBindCardCachedIdentityInfoModel.h
//  CJPaySandBox
//
//  Created by wangxiaohong on 2022/12/2.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayBindCardChooseIDType) {
    CJPayBindCardChooseIDTypeNormal = 0,
    CJPayBindCardChooseIDTypeHK = 1,
    CJPayBindCardChooseIDTypeTW = 2,
    CJPayBindCardChooseIDTypePD = 3,
    CJPayBindCardChooseIDTYpeHKRP = 4,
    CJPayBindCardChooseIDTYpeTWRP = 5,
};

@interface CJPayBindCardCachedIdentityInfoModel : JSONModel

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *identity;
@property (nonatomic, assign) CJPayBindCardChooseIDType selectedIDType;
@property (nonatomic, copy) NSString *nationalityCode;
@property (nonatomic, copy) NSString *nationalityDesc;
@property (nonatomic, assign) NSTimeInterval cachedBeginTime; //缓存开始时间

@end

NS_ASSUME_NONNULL_END
