//
//  CJPayQueryBindBytepayResponse.h
//  Pods
//
//  Created by 徐天喜 on 2022/8/31.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayErrorButtonInfo;
@interface CJPayQueryBindBytepayResponse : CJPayBaseResponse

@property (nonatomic, assign) BOOL isComplete;
@property (nonatomic, assign) BOOL isLnyxURL;
@property (nonatomic, copy) NSString *redirectURL;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@end

NS_ASSUME_NONNULL_END
