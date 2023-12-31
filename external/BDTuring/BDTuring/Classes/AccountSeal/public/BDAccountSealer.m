//
//  BDAccountSealer.m
//  BDTuring
//
//  Created by bob on 2020/3/4.
//

#import "BDAccountSealer.h"
#import "BDAccountSealer+Model.h"
#import "BDTuring+Private.h"
#import "BDAccountSealView.h"
#import "BDTuringConfig.h"

#import "BDAccountSealEvent.h"
#import "BDAccountSealConstant.h"
#import "BDTuringCoreConstant.h"
#import "WKWebView+Piper.h"
#import "BDTuringPiper.h"
#import "BDTuringUtility.h"
#import "BDTuringVerifyModel+Config.h"

#import "BDAccountSealModel.h"
#import "BDAccountSealResult+Creator.h"
#import "BDTuringConfig+AccountSeal.h"
#import "NSDictionary+BDTuring.h"
#import "NSData+BDTuring.h"
#import "BDTNetworkManager.h"
#import "BDTuringSettings.h"
#import "BDTuringSettingsKeys.h"
#import "BDAccountSealResult+Creator.h"

@interface BDAccountSealer ()

@property (nonatomic, strong) BDTuringConfig *config;
@property (nonatomic, strong) BDAccountSealEvent *eventService;
@property (nonatomic, assign) BOOL isShowSealView;
@property (nonatomic, assign) long long startLoadTime;
@property (nonatomic, strong) BDAccountSealModel *model;

@end

@implementation BDAccountSealer

- (instancetype)initWithTuring:(BDTuring *)turing {
    return [self initWithConfig:turing.config];
}

- (instancetype)initWithConfig:(BDTuringConfig *)config {
    self = [super init];
    if (self) {
        long long startTime = CFAbsoluteTimeGetCurrent() * 1000;
        self.startLoadTime = startTime;
        self.config = config;
        BDAccountSealEvent *eventService = [BDAccountSealEvent sharedInstance];
        eventService.config = config;
        self.eventService = eventService;
        self.isShowSealView = NO;
        
        long long duration = CFAbsoluteTimeGetCurrent() * 1000 - startTime;
        NSMutableDictionary *param = [NSMutableDictionary new];
        [param setValue:@(duration) forKey:kBDTuringDuration];
        [eventService collectEvent:BDAccountSealEventSDKStart data:param];
    }
    
    return self;
}

- (void)popVerifyViewWithModel:(BDAccountSealModel *)model {
    NSCAssert(model, @"model should not be nil");
    NSCAssert(model.navigate, @"navigate should not be nil");
    NSCAssert(model.callback, @"callback should not be nil");
    if (model == nil) {
        return;
    }
    
    if (![model validated]) {
        [model handleResult:[BDAccountSealResult unsupportResult]];
        return;
    }
    
    if (@available(iOS 8.0, *)) {
        /// do nothing
    } else {
        [model handleResult:[BDAccountSealResult unsupportResult]];
        NSMutableDictionary *param = [NSMutableDictionary new];
        [param setValue:@(BDAccountSealResultSystemVersionLow) forKey:kBDTuringVerifyParamResult];
        [self.eventService collectEvent:BDAccountSealEventResult data:param];
        return;
    }
    
    if (self.isShowSealView) {
        [model handleResult:[BDAccountSealResult conflictResult]];
        NSMutableDictionary *param = [NSMutableDictionary new];
        [param setValue:@(BDAccountSealResultConflict) forKey:kBDTuringVerifyParamResult];
        [self.eventService collectEvent:BDAccountSealEventResult data:param];
        return;
    }
    model.appID = self.config.appID;
    [self popWithModel:model];
}

- (void)queryStatusWithModel:(BDAccountSealModel *)model {
    BDTuringConfig *config = self.config;
    NSString *appID = self.config.appID;
    NSString *region = model.region;
    BDTuringSettings *settings = [BDTuringSettings settingsForAppID:appID];
    NSString *host = [settings requestURLForPlugin:kBDTuringSettingsPluginSeal
                                           URLType:kBDTuringSettingsHost
                                            region:region];
    
    NSString *requestURL = turing_requestURLWithPath(host, @"self/unpunish/v1/apply");
    NSDictionary *query = [config sealRequestQueryParameters];
    BDTuringNetworkFinishBlock netCallback = ^(NSData *response) {
        NSDictionary *resp = [response turing_objectFromJSONData];
        BDAccountSealResult *result = [BDAccountSealResult new];
        result.resultCode = [resp turing_integerValueForKey:@"status_code"];
        result.statusCode = result.resultCode;
        result.message = [resp turing_stringValueForKey:@"message"];
        [model handleResult:result];
    };
    [BDTNetworkManager asyncRequestForURL:requestURL
                                   method:@"GET"
                          queryParameters:query
                           postParameters:nil
                                 callback:netCallback
                            callbackQueue:nil
                                  encrypt:NO
                                  tagType:BDTNetworkTagTypeManual];
}

@end
