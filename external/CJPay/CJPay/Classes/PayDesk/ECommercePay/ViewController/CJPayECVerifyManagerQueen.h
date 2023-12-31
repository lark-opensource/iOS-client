//
//  CJPayECVerifyManagerQueen.h
//  Pods
//
//  Created by wangxiaohong on 2020/11/15.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseVerifyManagerQueen.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayECVerifyManagerQueen : CJPayBaseVerifyManagerQueen

@property (nonatomic, assign, readonly) NSTimeInterval beforeConfirmRequestTimestamp;
@property (nonatomic, assign, readonly) NSTimeInterval afterConfirmRequestTimestamp;
@property (nonatomic, assign, readonly) NSTimeInterval afterQueryResultTimestamp;

@end

NS_ASSUME_NONNULL_END
