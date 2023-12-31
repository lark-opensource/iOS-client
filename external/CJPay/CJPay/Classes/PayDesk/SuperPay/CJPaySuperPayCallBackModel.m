//
//  CJPaySuperPayCallBackModel.m
//  CJPaySandBox
//
//  Created by 郑秋雨 on 2023/2/7.
//

#import "CJPaySuperPayCallBackModel.h"
#import "CJPaySuperPayQueryRequest.h"

@implementation CJPaySuperPayCallBackModel

- (instancetype)initWithChannelType:(CJPayChannelType)type resultType:(CJPayResultType)resultType response:(CJPaySuperPayQueryResponse *)response {
    self = [super init];
    if (self) {
        self.channelType = type;
        self.resultType = resultType;
        self.paymentInfo = response.ext;
    }
    return self;
}

@end
