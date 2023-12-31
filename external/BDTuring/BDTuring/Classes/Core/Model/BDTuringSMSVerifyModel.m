//
//  BDTuringSMSVerifyModel.m
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDTuringSMSVerifyModel.h"
#import "BDTuringVerifyModel+Config.h"
#import "BDTuringVerifyModel+View.h"

#import "BDTuringVerifyState.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringVerifyViewDefine.h"
#import "BDTuringSMSVerifyView.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringUIHelper.h"
#import "BDTuringMacro.h"


@interface BDTuringSMSVerifyModel ()

@property (nonatomic, copy) NSString *scene;

@end

@implementation BDTuringSMSVerifyModel

- (instancetype)init {
    self = [super init];
    if (self) {
        self.plugin = kBDTuringSettingsPluginSMS;
        self.verifyType = BDTuringVerifyTypeSMS;
        [self createState];
    }
    
    return self;
}

+ (instancetype)modelWithScene:(NSString *)scene {
    BDTuringSMSVerifyModel *result = [self new];
    result.scene = scene;
    
    return result;
}

- (BDTuringVerifyView *)createVerifyView {
    CGRect bounds = [UIScreen mainScreen].bounds;
    return [[BDTuringSMSVerifyView alloc] initWithFrame:bounds];
}

- (void)appendCommonKVParameters:(NSMutableDictionary *)paramters {
    [super appendCommonKVParameters:paramters];
}


@end
