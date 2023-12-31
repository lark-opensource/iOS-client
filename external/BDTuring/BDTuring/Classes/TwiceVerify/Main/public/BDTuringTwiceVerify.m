//
//  BDTuringTwiceVerify.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/11/2.
//

#import "BDTuringTwiceVerify.h"
#import "BDTuringTVTracker.h"
#import "BDTuringTVHelper.h"
#import "BDTuringTVViewController.h"
#import "BDTuringTwiceVerifyModel+Creator.h"
#import "BDTuringTVConverter.h"
#import "BDTuring.h"
#import "BDTuring+Private.h"
#import "BDTuringConfig.h"
#import "BDTuringParameterVerifyModel.h"
#import "BDTuringServiceCenter.h"
#import "BDTuringConfig+Parameters.h"
#import "BDTuringCoreConstant.h"
#import "BDTuringMacro.h"
#import "BDTuringSettings.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringUtility.h"
#import "BDTuringPresentView.h"
#import "BDTNetworkManager.h"

@interface BDTuringTwiceVerify () <BDTuringService>

@property (nonatomic, copy) NSString *appID;
@property (nonatomic, copy) NSString *serviceName;

@property (nonatomic, strong) BDTuringSettings *settings;

@property (nonatomic, copy) BDTuringTVResponseCallBack callBack;
@property (nonatomic, copy) NSString *scene;

@end

@implementation BDTuringTwiceVerify

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[BDTuringParameter sharedInstance] addCreator:[BDTuringTwiceVerifyModel class]];
    });
}

+ (instancetype)twiceVerifyWithAppID:(NSString *)appid {
    NSCAssert(appid != nil, @"appID should not be nil");
    NSString *serviceName = NSStringFromClass([BDTuringTwiceVerifyModel class]);
    BDTuringTwiceVerify *tvVerify = [[BDTuringServiceCenter defaultCenter] serviceForName:serviceName appID:appid];
    
    if (![tvVerify isKindOfClass:[self class]]) {
        return nil;
    }
    
    return tvVerify;
}


+ (instancetype)twiceVerifyWithConfig:(BDTuringConfig *)config {
    BDTuringTwiceVerify *tvVerify = [self twiceVerifyWithAppID:config.appID];
    if (tvVerify == nil) {
        tvVerify = [[self alloc] initWithConfig:config];
    }
    return tvVerify;
}

- (instancetype)initWithConfig:(BDTuringConfig *)config {
    if (self = [super init]) {
        self.config = config;
        self.appID = config.appID;
        self.settings = [BDTuringSettings settingsForConfig:config];
        self.url = [self.settings requestURLForPlugin:kBDTuringSettingsPluginTwiceVerify
                                              URLType:kBDTuringSettingsURL
                                               region:turing_regionFromRegionType(config.regionType)];
        self.serviceName = NSStringFromClass([BDTuringTwiceVerifyModel class]);
        [[BDTuringServiceCenter defaultCenter] registerService:self];
    }
    
    return self;
}

- (void)popVerifyViewWithModel:(BDTuringVerifyModel *)model {
    BDTuringTwiceVerifyModel *tvModel = nil;
    if ([model isKindOfClass:[BDTuringParameterVerifyModel class]]) {
        tvModel = ((BDTuringParameterVerifyModel *)model).actualModel;
        tvModel.callback = model.callback;
    } else {
        tvModel = (BDTuringTwiceVerifyModel *)model;
    }
    [self popVerifyViewWithModel:tvModel callback:^(BDTuringTwiceVerifyResponse *response) {
        tvModel.callback(turing_tvReponseToResult(response));
    }];
}

- (void)popVerifyViewWithModel:(BDTuringTwiceVerifyModel *)model callback:(BDTuringTVResponseCallBack)callback {
    /// avoid assert
    dispatch_async(dispatch_get_main_queue(), ^{
        [self startWithRequest:turing_tvModelToRequest(model) completion:callback];
    });
}

- (void)startWithRequest:(BDTuringTwiceVerifyRequest *)request completion:(BDTuringTVResponseCallBack)completion {
    if (!request) {
        return;
    }
    self.callBack = completion;
    NSMutableDictionary *params = [request.params mutableCopy];
    if (!params || ![params isKindOfClass:[NSDictionary class]] || params.count == 0) {
        return ;
    }
    [params setValue:[self.config stringFromDelegateSelector:@selector(userID)] forKey:kBDTuringUserID];
    self.scene = request.params[kBDTuringTVScene];
    
    NSString *configStr = [params valueForKey:kBDTuringTVDecisionConfig];
    UIViewController *topViewController = request.superVC;
    if (!topViewController || [BDTuringPresentView defaultPresentView].isHidden) {
        topViewController = [BDTuringTVHelper getVisibleTopViewController];
    }
    BDTuringTVViewController *webVc = [[BDTuringTVViewController alloc] initWithParams:params];
    webVc.callBack = self.callBack;
    NSCAssert(self.url && self.url.length > 0, @"twice verify url should not be nil or empty");
    webVc.url = self.url;
    webVc.scene = self.scene;
    webVc.config = self.config;
    webVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [[BDTuringPresentView defaultPresentView] presentTwiceVerifyViewController:webVc];
//    [topViewController presentViewController:webVc animated:YES completion:nil];
    
    kBDTuringTVBlockType blockType;
    if ([configStr isEqualToString:kBDTuringTVBlockSms]) {
        blockType = kBDTuringTVBlockTypeSms;
    } else if ([configStr isEqualToString:kBDTuringTVBlockUpsms]) {
        blockType = kBDTuringTVBlockTypeUpsms;
    } else if ([configStr isEqualToString:kBDTuringTVBlockPassword]) {
        blockType = kBDTuringTVBlockTypePassword;
    } else {
        blockType = kBDTuringTVBlockTypeUnknown;
    }
    [BDTuringTVTracker trackerShowTwiceVerifyWithScene:self.scene type:blockType aid:self.config.appID];
}

- (void)requestVerifyAuthResultWithDomain:(NSString *)domain params:(NSDictionary *)params complete:(dispatch_block_t)complete {
    if (!domain || ![domain isKindOfClass:[NSString class]] || domain.length == 0) {
        NSAssert(NO, @"domain must not be nil!");
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/passport/safe/verify_req_order/", domain];
    
    BDTuringTwiceVerifyNetworkFinishBlock finishedBlock = ^(NSError *error, NSData *data, NSInteger statusCode) {
        if (complete) {
            complete();
        }
    };
    
    [BDTNetworkManager tvRequestForJSONWithResponse:url
                                             params:params
                                             method:@"GET"
                                   needCommonParams:YES
                                        headerField:nil
                                           callback:finishedBlock
                                            tagType:BDTNetworkTagTypeManual];
}




@end
