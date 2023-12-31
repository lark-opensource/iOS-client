//
//  BDTuringVerifyModel+Creator.m
//  BDTuring
//
//  Created by bob on 2020/7/12.
//

#import "BDTuringPictureVerifyModel.h"
#import "BDTuringVerifyModel+Creator.h"
#import "BDTuringParameterVerifyModel.h"
#import "BDTuringVerifyModel+Parameter.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringPictureVerifyModel.h"
#import "BDTuringSMSVerifyModel.h"
#import "BDTuringParameter.h"

@implementation BDTuringVerifyModel (Creator)

+ (instancetype)pictureModelWithCode:(NSInteger)code {
    return [BDTuringPictureVerifyModel modelWithCode:code];
}

+ (instancetype)parameterModelWithParameter:(NSDictionary *)parameter {
    return [[BDTuringParameter sharedInstance] modelWithParameter:parameter];
}

+ (instancetype)smsModelWithScene:(NSString *)scene {
    return [BDTuringSMSVerifyModel modelWithScene:scene];
}

+ (instancetype)preloadModel {
    BDTuringPictureVerifyModel *model = [BDTuringPictureVerifyModel new];
    model.region = kBDTuringRegionCN;
    model.hideLoading = YES;
    return model;
}

@end
