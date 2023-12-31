//
//  CJPayDataSecurityModel.h
//  Pods
//
//  Created by gh on 2021/9/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDataSecurityModel : NSObject

+ (instancetype)shared;
- (void)bindViewControllerToModel:(UIViewController *)vc;

@end

NS_ASSUME_NONNULL_END
