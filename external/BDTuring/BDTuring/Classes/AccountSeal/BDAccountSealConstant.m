//
//  BDAccountSealConstant.m
//  BDTuring
//
//  Created by bob on 2020/3/1.
//

#import "BDAccountSealConstant.h"
#import "BDTuringUtility.h"

NSString *const BDAccountSealPiperNameOnResult        = @"unblock.notifyResult";
NSString *const BDAccountSealPiperNameGetData         = @"unblock.getData";
NSString *const BDAccountSealPiperNamePageEnd         = @"unblock.pageEnd";
NSString *const BDAccountSealPiperNameShowAlert       = @"unblock.showNativeAlert";
NSString *const BDAccountSealPiperNameVerify          = @"unblock.verify";
NSString *const BDAccountSealPiperNameToPage          = @"unblock.navigateToPage";
NSString *const BDAccountSealPiperNameShow            = @"unblock.showContent";
NSString *const BDAccountSealPiperNameNetwork         = @"unblock.network.request";
NSString *const BDAccountSealPiperNameThemeSettings   = @"unblock.getSettings";
NSString *const BDAccountSealPiperNameEventToNative   = @"unblock.eventToNative";

NSString *const BDAccountSealEventSDKStart          = @"self_unpunish_sdk_init";
NSString *const BDAccountSealEventSDKCall           = @"self_unpunish_sdk_call";
NSString *const BDAccountSealEventWebViewSuccess    = @"self_unpunish_sdk_webView_success";
NSString *const BDAccountSealEventWebViewFail       = @"self_unpunish_sdk_webView_fail";
NSString *const BDAccountSealEventVerifyResult      = @"self_unpunish_sdk_verify_result";
NSString *const BDAccountSealEventResult            = @"self_unpunish_sdk_result";


NSString *const kBDAccountSealTicket          = @"ticket";

NSString *const kBDAccountSealAlertTitle            = @"title";
NSString *const kBDAccountSealAlertMessage          = @"message";
NSString *const kBDAccountSealAlertOptions          = @"options";

NSString *const BDAccountSealEventPrefix     = @"self_unpunish_";
NSString *const BDAccountSealEventKeyWord    = @"self_unpunish";

NSString *const BDAccountSealThemeStringDark      = @"dark";
NSString *const BDAccountSealThemeStringLight     = @"light";
NSString *const kBDTuringNativeThemeMode    = @"douyin_theme_mode";

NSString * turing_sealDatabaseFile() {
    return [turing_sdkDocumentPath() stringByAppendingPathComponent:@"bd_seal_v1.sqlite"];
}

