//
//  CJPayMemGetOneKeySignBankUrlResponse.h
//  Pods
//
//  Created by renqiang on 2021/6/3.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayErrorButtonInfo;
@interface CJPayMemGetOneKeySignBankUrlResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *bankUrl;
@property (nonatomic, copy) NSString *postData;
@property (nonatomic, assign) BOOL isMiniApp;

@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@end

NS_ASSUME_NONNULL_END
