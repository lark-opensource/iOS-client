//
//  BDTuringLynxViewController.m
//  BDTuring
//
//  Created by yanming.sysu on 2021/2/8.
//

#import "BDTuringLynxViewController.h"
#import "BDTuringLynxPlugin.h"
#import "BDTNetworkManager.h"

#import <Lynx/BDLynxView.h>

static NSString * const cardID = @"lc487faf625f9bb509";
static NSString * const groupID = @"lc78399f246fdd855c";


static NSString * const turingRequestDecison = @"turing_request_decision";
static NSString * const decisionURL = @"https://rc-boe.snssdk.com/self/unpunish/v1/test_get_decision_conf_simple";


@interface BDTuringLynxViewController ()

@property (nonatomic, strong) BDLynxView *lynxView;

@end

@implementation BDTuringLynxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self registerFetchDecision];
    
    NSString *jsPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"template.js"];
    NSData *jsData = [NSData dataWithContentsOfFile:jsPath];
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.windows.firstObject;
        CGFloat topPadding = window.safeAreaInsets.top;
        self.lynxView = [[BDLynxView alloc] initWithFrame:CGRectMake(0, topPadding, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height - topPadding)];
    } else {
        self.lynxView = [[BDLynxView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
    }
    [self.lynxView setHeightMode:BDLynxViewSizeModeExact];
    [self.lynxView setWidthMode:BDLynxViewSizeModeExact];
    [self.view addSubview: self.lynxView];
    
    self.lynxView.data = jsData;
    BDLynxViewBaseParams *params = [[BDLynxViewBaseParams alloc] init];
    params.localUrl = jsPath;
    params.channel = @"local_test";
    params.cardID = cardID;
    params.groupID = groupID;
    [self.lynxView loadLynxWithParams:params];
}

- (void)registerFetchDecision {
    [BDLynxBridge registerGlobalHandler:^(LynxView * _Nonnull lynxView, NSString * _Nonnull name, NSDictionary * _Nullable params, void (^ _Nonnull callback)(BDLynxBridgeStatusCode, id _Nullable)) {
        BDTuringNetworkFinishBlock finishBlock = ^(NSData *data){
            NSError *error = nil;
            NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            if (error == nil) {
                NSString *decision = [jsonObj valueForKey:@"decision_conf"];
                if ([decision isKindOfClass:[NSString class]]) {
                    NSDictionary *decisionConf = [NSJSONSerialization JSONObjectWithData:[decision dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
                    if (error == nil) {
                        callback(BDLynxBridgeCodeSucceed,decisionConf);
                    } else {
                        callback(BDLynxBridgeCodeSucceed,nil);
                    }
                } else {
                    callback(BDLynxBridgeCodeFail,nil);
                }
            } else {
                callback(BDLynxBridgeCodeFail, nil);
            }
        };
        [BDTNetworkManager asyncRequestForURL:decisionURL
                                       method:@"GET"
                              queryParameters:@{@"verify_type":@"slide"}
                               postParameters:nil
                                     callback:finishBlock
                                callbackQueue:dispatch_get_main_queue()
                                      encrypt:NO
                                      tagType:BDTNetworkTagTypeManual];
    } forMethod:turingRequestDecison];
}

@end
