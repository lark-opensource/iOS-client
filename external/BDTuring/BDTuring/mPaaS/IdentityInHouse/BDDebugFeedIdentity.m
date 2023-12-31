//
//  BDDebugFeedIdentity.m
//  BDTuring
//
//  Created by bob on 2020/6/2.
//

#import "BDDebugFeedIdentity.h"
#import "BDDebugFeedTuring.h"
#import "BDTuringIdentity.h"
#import "BDTuringStartUpTask.h"
#import "BDTuringConfig+Identity.h"
#import "NSDictionary+BDTuring.h"
#import "BDTuringIdentityResult.h"
#import "BDTuringIdentityModel.h"

#import <BDStartUp/BDApplicationInfo.h>
#import <BDStartUp/BDStartUpGaia.h>
#import <BDStartUp/BDDebugStartUpTask.h>
#import <BDDebugTool/BDDebugFeedLoader.h>
#import <BDDebugTool/BDDebugSettingModel.h>
#import <BDDebugTool/BDDebugSettings.h>
#import <BDDebugTool/UIViewController+BDDebugAlert.h>
#import <BDAssert/BDAssert.h>

#import <byted_cert/BytedCertTTJSBridgeHandler.h>
#import <byted_cert/BytedCertInterface.h>
#import <byted_cert/BytedCertUserInfo.h>
#import <byted_cert/BytedCertDefine.h>

BDAppInHouseConfigFunction () {
    [[BDDebugStartUpTask sharedInstance] addCheckBlock:^NSString *{
        BDAssert(![BDApplicationInfo sharedInstance].isI18NApp, @"实名认证不支持海外产品");
        return nil;
    }];
}

@interface BDDebugFeedIdentity ()<BDTuringIdentityHandler, BytedCertProgressDelegate>

@property (nonatomic, strong) BDTuringIdentity *identity;
@property (nonatomic, strong) BDTuringIdentityModel *model;

+ (instancetype)sharedInstance;
+ (NSArray<BDDebugSectionModel *> *)feeds;

@end

BDAppAddDebugFeedFunction() {
    [BDDebugFeedIdentity sharedInstance];
    BDDebugFeedTuring *debug = [BDDebugFeedTuring sharedInstance];

    debug.identityFeed = [BDDebugFeedIdentity feeds];
}

@implementation BDDebugFeedIdentity

+ (instancetype)sharedInstance {
    static BDDebugFeedIdentity *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.identity = [BDTuringIdentity identityWithAppID:[BDDebugFeedTuring sharedInstance].config.appID];
        self.identity.handler = self;
    }
    
    return self;
}

- (void)popVerifyViewWithModel:(BDTuringIdentityModel *)model {
    self.model = model;
    
    NSMutableDictionary *param = [[BDDebugFeedTuring sharedInstance].config identityParameterWithModel:model];
    /// debug need userID
    NSString *userID = [[BDDebugFeedTuring sharedInstance].config.delegate userID];
    [param setValue:userID forKey:@"user_id"];
    BytedCertInterface* bytedIf = [BytedCertInterface sharedInstance];
    [bytedIf addProgressDelegate:self];

    BytedCertTTJSBridgeHandler* handler = [[BytedCertTTJSBridgeHandler alloc] initWithParams:param];
    [handler start];
}

- (void)progressFinishWithType:(BytedCertProgressType)progressType params:(NSDictionary *)params {
    if (progressType != BytedCertProgressTypeIdentityVerify) {
        return;
    }
    [[BytedCertInterface sharedInstance] removeProgressDelegate:self];
    
    NSDictionary *ext = [params turing_dictionaryValueForKey:BytedCertJSBParamsExtData];
    NSInteger errorCode = [params turing_integerValueForKey:BytedCertJSBParamsErrorCode];
    NSString *message = [params turing_stringValueForKey:BytedCertJSBParamsErrorMsg];
    NSDictionary *state = [ext turing_dictionaryValueForKey:@"state"];
    BDTuringIdentityCode identityAuthCode = [state turing_integerValueForKey:@"identity_auth_state"];
    BDTuringIdentityCode livingDetectCode = [state turing_integerValueForKey:@"living_detect_state"];
    BDTuringIdentityResult *result = [BDTuringIdentityResult new];
    result.identityAuthCode = identityAuthCode;
    result.livingDetectCode = livingDetectCode;
    result.serverCode = errorCode;
    result.message = message;
    result.ticket = [BytedCertUserInfo sharedInstance].ticket;
    
    [self.model handleResult:result];
    self.model = nil;
}

+ (NSArray<BDDebugSectionModel *> *)feeds {
    NSMutableArray<BDDebugSectionModel *> *sections = [NSMutableArray new];
    
    [sections addObject:({
        BDDebugSectionModel *model = [BDDebugSectionModel new];
        model.title = @"实名验证模块";
        NSMutableArray<BDDebugFeedModel *> *feeds = [NSMutableArray new];
        
        [feeds addObject:({
            BDDebugFeedModel *model = [BDDebugFeedModel new];
            model.title = @"开始实名验证";
            model.navigateBlock = ^(BDDebugFeedModel *feed, UINavigationController *navigate) {
                BDTuringIdentityModel *model = [BDTuringIdentityModel new];
                model.scene = @"scene_test";
                model.callback = ^(BDTuringVerifyResult * verify) {
                    BDTuringIdentityResult *result = (BDTuringIdentityResult *)verify;
                    NSString *mmessage = [NSString stringWithFormat:@"活体验证结果 identityAuthCode(%zd) livingDetectCode(%zd)",result.identityAuthCode, result.livingDetectCode];
                    [navigate bdd_showAlertWithMessage:mmessage];
                };
                [[BDDebugFeedIdentity sharedInstance].identity popVerifyViewWithModel:model];
            };
           model;
        })];
        
        model.feeds = feeds;
        model;
    })];
    
    return sections;
}

@end
