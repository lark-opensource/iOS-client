//
//  CJPayDouPayProcessVerifyManagerQueen.h
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/5/31.
//

#import "CJPayBaseVerifyManagerQueen.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDouPayProcessVerifyManagerQueen : CJPayBaseVerifyManagerQueen

@property (nonatomic, assign, readonly) NSTimeInterval beforeConfirmRequestTimestamp;
@property (nonatomic, assign, readonly) NSTimeInterval afterConfirmRequestTimestamp;
@property (nonatomic, assign, readonly) NSTimeInterval afterQueryResultTimestamp;

@end

NS_ASSUME_NONNULL_END
