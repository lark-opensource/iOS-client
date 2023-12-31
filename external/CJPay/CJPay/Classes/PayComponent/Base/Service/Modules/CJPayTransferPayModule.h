//
//  CJPayTransferPayModule.h
//  CJPaySandBox
//
//  Created by shanghuaijun on 2023/5/21.
//

#import <Foundation/Foundation.h>
#import "CJPayManagerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayTransferPayModule <NSObject>

- (void)startTransferPayWithParams:(NSDictionary *)params
                        completion:(void (^)(CJPayManagerResultType type, NSString *errorMsg))completion;
@end

NS_ASSUME_NONNULL_END
