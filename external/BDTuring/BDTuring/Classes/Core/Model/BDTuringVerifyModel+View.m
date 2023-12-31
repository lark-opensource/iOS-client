//
//  BDTuringVerifyModel+View.m
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDTuringVerifyModel+View.h"
#import "BDTuringVerifyModel+Config.h"

#import "BDTuringConfig+Parameters.h"
#import "BDTuringVerifyState.h"
#import "BDTuringUtility.h"
#import "BDTuringVerifyView.h"
#import "BDTuringSettings.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringCoreConstant.h"

@implementation BDTuringVerifyModel (View)

- (BDTuringVerifyView *)createVerifyView {
    CGRect bounds = [UIScreen mainScreen].bounds;
    return [[BDTuringVerifyView alloc] initWithFrame:bounds];
}

- (void)configVerifyView:(BDTuringVerifyView *)verifyView {
}

- (void)loadVerifyView:(BDTuringVerifyView *)verifyView {
    [self configVerifyView:verifyView];
    BDTuringConfig *config = verifyView.config;
    NSMutableDictionary *query = [config turingWebURLQueryParameters];
    query = [self configQuery:query];
    
    if (verifyView.isPreloadVerifyView) {
        query = [self addPreloadQuery:query];
    }
    
    [self loadVerifyView:verifyView withQuery:query];
}

- (NSMutableDictionary *)addPreloadQuery:(NSMutableDictionary *)query {
    [query setValue:@(1) forKey:kBDTuringPreload];
    return query;
}

- (NSMutableDictionary *)configQuery:(NSMutableDictionary *)query {
    BDTuringSettings *settings = [BDTuringSettings settingsForAppID:self.appID];
    NSString *region = self.region;
    NSString *plugin = self.plugin;
    
    NSString *host = [settings requestURLForPlugin:plugin
                                           URLType:kBDTuringSettingsHost
                                            region:region];
    NSString *backupHost = [settings requestURLForPlugin:plugin
                                                 URLType:kBDTuringSettingsBackupHost
                                                  region:region];
    [query setValue:host forKey:kBDTuringVerifyHost];
    [query setValue:backupHost forKey:kBDTuringSettingsBackupHost];
    [query setValue:@(1) forKey:kBDTuringUseJSBRequest];
    [query setValue:@(1) forKey:kBDTuringUseNativeReport];
    NSCAssert(host, @"host should not be nil");
    return query;
}

- (void)loadVerifyView:(BDTuringVerifyView *)verifyView withQuery:(NSMutableDictionary *)query {
    BDTuringSettings *settings = [BDTuringSettings settingsForAppID:self.appID];
    NSString *requestURL = [settings requestURLForPlugin:self.plugin
                                                 URLType:kBDTuringSettingsURL
                                                  region:self.region];
    requestURL = turing_requestURLWithQuery(requestURL, query);

    NSCAssert(requestURL, @"requestURL should not be nil");
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestURL]];
    [verifyView.webView loadRequest:request];
}


@end
