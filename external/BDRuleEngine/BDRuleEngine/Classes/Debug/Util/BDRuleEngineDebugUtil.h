//
//  BDRuleEngineDebugUtil.h
//  BDRuleEngine-Core-Debug-Expression-Service
//
//  Created by Chengmin Zhang on 2022/6/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDRuleEngineDebugUtil : NSObject

+ (void)showAlertWithTitle:(NSString *)title message:(NSString *)message viewController:(UIViewController *)vc;

@end

NS_ASSUME_NONNULL_END
