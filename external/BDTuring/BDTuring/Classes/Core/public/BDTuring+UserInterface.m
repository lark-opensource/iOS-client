//
//  BDTuring+UserInterface.m
//  BDTuring
//
//  Created by bob on 2020/6/16.
//

#import "BDTuring+UserInterface.h"
#import "BDTuringUIHelper.h"

@implementation BDTuring (UserInterface)

+ (void)setForbidLandscape:(BOOL)forbid {
    [BDTuringUIHelper sharedInstance].turingForbidLandscape = forbid;
}

+ (void)setDisableLoadingView:(BOOL)disable {
    [BDTuringUIHelper sharedInstance].disableLoadingView = disable;
}

+ (void)setVerifyTheme:(NSDictionary *)theme {
    [BDTuringUIHelper sharedInstance].verifyThemeDictionary = theme;
}

+ (void)setVerifyText:(NSDictionary *)text {
    [BDTuringUIHelper sharedInstance].verifyTextDictionary = text;
}

+ (void)setSMSTheme:(NSDictionary *)theme {
    [BDTuringUIHelper sharedInstance].smsThemeDictionary = theme;
}

+ (void)setSMSText:(NSDictionary *)text {
    [BDTuringUIHelper sharedInstance].smsTextDictionary = text;
}

+ (void)setQATheme:(NSDictionary *)theme {
    [BDTuringUIHelper sharedInstance].qaThemeDictionary = theme;
}

+ (void)setQAText:(NSDictionary *)text {
    [BDTuringUIHelper sharedInstance].qaTextDictionary = text;
}

@end
