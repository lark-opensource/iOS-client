//
//  BDUGTokenShareModel.h.m
//  BDUGShare
//
//  Created by zengzhihui on 2018/5/31.
//

#import "BDUGImageShareModel.h"

@implementation BDUGImageShareContentModel

@end

#pragma mark - BDUGImageShareAnalysisResultModel

@implementation BDUGImageShareAnalysisResultModel

+ (instancetype)resultModelWithResultInfo:(NSString *)resultInfo {
    return [[BDUGImageShareAnalysisResultModel alloc] initWithResultInfo:resultInfo];
}

- (instancetype)initWithResultInfo:(NSString *)resultInfo {
    self = [super init];
    if (self) {
        _resultInfo = resultInfo;
    }
    return self;
}
@end
