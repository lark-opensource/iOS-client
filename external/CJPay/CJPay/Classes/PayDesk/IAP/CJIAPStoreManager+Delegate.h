//
//  CJIAPStoreManager+Delegate.h
//  CJPay
//
//  Created by 王新华 on 2019/6/18.
//

#import <Foundation/Foundation.h>
#import "CJIAPStoreManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJIAPStoreManager(Delegate)<CJIAPStoreDelegate>


- (void)eventV:(NSString *)event params:(NSDictionary *)params productID:(NSString *)productID;

@end

NS_ASSUME_NONNULL_END
