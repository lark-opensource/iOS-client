//
//  CJPayBrandPromoteABTestManager.h
//  Pods
//
//  Created by 易培淮 on 2021/6/9.
//

#import <Foundation/Foundation.h>
#import "CJPaySettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBrandPromoteABTestManager : NSObject

@property (nonatomic, strong) CJPayBrandPromoteModel *model;

+ (instancetype)shared;
- (BOOL)isHitTest;


@end

NS_ASSUME_NONNULL_END
