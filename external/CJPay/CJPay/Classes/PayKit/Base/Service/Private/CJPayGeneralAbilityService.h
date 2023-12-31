//
//  CJPayGeneralAbilityService.h
//  DouYin
//
//  Created by ByteDance on 2023/3/25.
//

#ifndef CJPayGeneralAbilityService_h
#define CJPayGeneralAbilityService_h
@protocol CJPayAPIDelegate;

typedef NS_ENUM(NSInteger, CJPayGeneralAbilityAction) {
    CJPayGeneralAbilityActionShowProtocol = 1,
    CJPayGeneralAbilityActionReturnGeneralParams,
};

@protocol CJPayGeneralAbilityService <NSObject>

- (void)i_wekeByGeneralAbility:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate;

@end



#endif /* CJPayGeneralAbilityService_h */
