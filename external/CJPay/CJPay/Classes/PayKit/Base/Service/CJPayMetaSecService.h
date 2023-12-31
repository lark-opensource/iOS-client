//
//  CJPayMetaSecService.h
//  Pods
//
//  Created by 易培淮 on 2021/9/13.
//

#ifndef CJPayMetaSecService_h
#define CJPayMetaSecService_h

#import "CJMetaSecDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayMetaSecService <NSObject>

- (void)i_registerMetaSecDelegate:(id<CJMetaSecDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END


#endif /* CJPayMetaSecService_h */
