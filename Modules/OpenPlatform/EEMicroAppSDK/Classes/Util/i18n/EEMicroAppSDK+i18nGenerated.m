/**
Warning: Do Not Edit It!
Created by EEScaffold, if you want to edit it please check the manual of EEScaffold
Toolchains For EE

______ ______ _____        __
|  ____|  ____|_   _|      / _|
| |__  | |__    | |  _ __ | |_ _ __ __ _
|  __| |  __|   | | | '_ \|  _| '__/ _` |
| |____| |____ _| |_| | | | | | | | (_| |
|______|______|_____|_| |_|_| |_|  \__,_|

Meta信息不要删除！如果冲突，重新生成BundleI18n就好
---Meta---
{
"keys":{
"LittleApp_UserInfoPermission_BluetoothPermDesc":{
"hash":"Evw",
"#vars":0
},
"LittleApp_UserInfoPermission_BluetoothPermListDisplay":{
"hash":"ka8",
"#vars":0
},
"LittleApp_UserInfoPermission_BluetoothPermName":{
"hash":"qTc",
"#vars":0
},
"LittleApp_UserInfoPermission_BluetoothPermNameFull":{
"hash":"6/c",
"#vars":0
},
"add_address":{
"hash":"sAE",
"#vars":0
},
"address_already_exists":{
"hash":"XUQ",
"#vars":0
},
"app_update_tip":{
"hash":"GZQ",
"#vars":0
},
"brightness":{
"hash":"k94",
"#vars":0
},
"change_address":{
"hash":"80w",
"#vars":0
},
"contact":{
"hash":"adE",
"#vars":0
},
"continue_show_modal_exit":{
"hash":"Y1U",
"#vars":0
},
"continue_show_modal_no":{
"hash":"zuI",
"#vars":0
},
"continue_show_modal_tip":{
"hash":"ym0",
"#vars":0
},
"date_format_incorrect":{
"hash":"f6U",
"#vars":0
},
"detailed_address":{
"hash":"0I8",
"#vars":0
},
"device_info_desc":{
"hash":"s4g",
"#vars":0
},
"device_info_name":{
"hash":"CEM",
"#vars":0
},
"docs_nothing_found":{
"hash":"rA4",
"#vars":0
},
"docs_people_may_mention":{
"hash":"cHk",
"#vars":0
},
"docs_toolbar_high_light":{
"hash":"50k",
"#vars":0
},
"enter_bot":{
"hash":"Eos",
"#vars":0
},
"enter_detailed_address_information":{
"hash":"Dfk",
"#vars":0
},
"failed_to_connect_ide":{
"hash":"ghk",
"#vars":0
},
"get_address_failed":{
"hash":"FFo",
"#vars":0
},
"load_failed_and_retry":{
"hash":"rqI",
"#vars":0
},
"my_address":{
"hash":"Mr4",
"#vars":0
},
"name":{
"hash":"jaE",
"#vars":0
},
"no_internet_connection":{
"hash":"/58",
"#vars":0
},
"not_logged_in":{
"hash":"F+Y",
"#vars":0
},
"open_with_other_app":{
"hash":"sLc",
"#vars":0
},
"phone_number":{
"hash":"org",
"#vars":0
},
"phone_number_invalid":{
"hash":"fQQ",
"#vars":0
},
"please_select":{
"hash":"peg",
"#vars":0
},
"please_wait":{
"hash":"1II",
"#vars":0
},
"select_region":{
"hash":"DtQ",
"#vars":0
},
"share_fail":{
"hash":"1lQ",
"#vars":0
},
"show_prompt_ok":{
"hash":"uYk",
"#vars":0
},
"show_prompt_placeholder":{
"hash":"NOg",
"#vars":0
},
"submission_failed":{
"hash":"eZA",
"#vars":0
},
"sure_to_test_on_device":{
"hash":"a+o",
"#vars":0
},
"update_now":{
"hash":"R1g",
"#vars":0
}
},
"name":"EEMicroAppSDK",
"short_key":true,
"config":{
"positional-args":true,
"use-native":true,
"res_dir":"../../Assets/EMAI18n.bundle",
"code_dir":"../../Classes/Util/i18n",
"objc":{
"pre_code":"#import <OPFoundation/OPBundle.h>\n#import \"EMAI18n.h\"\n#import <TTMicroApp/TTMicroApp-Swift.h>\n#import <OPFoundation/OPFoundation-Swift.h>\n\nstatic NSString *stringForKey(NSString *key) {\n    NSBundle *bundle = [OPBundle bundle];\n    NSString *tableName = BDPLanguageHelper.stringsLanguage;\n    NSString *bundleName = @\"EMAI18n\";\n    NSURL *url = [bundle URLForResource:bundleName withExtension:@\"bundle\"];\n    if (url) { bundle = [NSBundle bundleWithURL:url]; }\n    NSString *locale = [BDPLanguageHelper getLocaleWith:key in:bundle moduleName:@\"EEMicroAppSDK\"];\n    if (locale) {\n        return locale;\n    }\n    if (!url) {\n        return NSLocalizedStringFromTable(key, tableName, nil);\n    }\n\n    // If the current language file does not exist, then use English as default\n    if (![bundle pathForResource:tableName ofType:@\"strings\"]) {\n        tableName = @\"en-US\";\n    }\n    return NSLocalizedStringFromTableInBundle(key, tableName, bundle, nil);\n}\n"
}
},
"fetch":{
"resources":[{
"projectId":2207,
"namespaceId":[34815,38483,34810]
},{
"projectId":2094,
"namespaceId":[34132,34137]
},{
"projectId":2085,
"namespaceId":[34083]
},{
"projectId":2103,
"namespaceId":[34186,34191,34187]
},{
"projectId":2108,
"namespaceId":[34221,34216]
},{
"projectId":2187,
"namespaceId":[34695]
},{
"projectId":2521,
"namespaceId":[38139]
},{
"projectId":3545,
"namespaceId":[37986]
},{
"projectId":4394,
"namespaceId":[41385]
},{
"projectId":8217,
"namespaceId":[50340,50342,50344],
"support_single_param":true
},{
"projectId":3788,
"namespaceId":[38915]
},{
"projectId":2095,
"namespaceId":[34143,34138]
},{
"projectId":3129,
"namespaceId":[37171]
},{
"projectId":2268,
"namespaceId":[35181],
"support_single_param":true
},{
"projectId":2176,
"namespaceId":[34629,41969,41970]
},{
"projectId":2085,
"namespaceId":[34078,34083]
},{
"projectId":2113,
"namespaceId":[34251,34246]
},{
"projectId":2086,
"namespaceId":[38121,34089]
},{
"projectId":2231,
"namespaceId":[34959]
},{
"projectId":8770,
"namespaceId":[52445,66909]
},{
"projectId":23858,
"namespaceId":[81561]
}],
"locale":["en-US","zh-CN","zh-TW","zh-HK","ja-JP","id-ID","de-DE","es-ES","fr-FR","it-IT","pt-BR","vi-VN","ru-RU","hi-IN","th-TH","ko-KR","ms-MY"]
}
}
---Meta---

TODO: 插值的支持
*/

#import "EEMicroAppSDK+i18nGenerated.h"
#import <OPFoundation/OPBundle.h>
#import "EMAI18n.h"
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>

static NSString *stringForKey(NSString *key) {
    NSBundle *bundle = [OPBundle bundle];
    NSString *tableName = BDPLanguageHelper.stringsLanguage;
    NSString *bundleName = @"EMAI18n";
    NSURL *url = [bundle URLForResource:bundleName withExtension:@"bundle"];
    if (url) { bundle = [NSBundle bundleWithURL:url]; }
    NSString *locale = [BDPLanguageHelper getLocaleWith:key in:bundle moduleName:@"EEMicroAppSDK"];
    if (locale) {
        return locale;
    }
    if (!url) {
        return NSLocalizedStringFromTable(key, tableName, nil);
    }

    // If the current language file does not exist, then use English as default
    if (![bundle pathForResource:tableName ofType:@"strings"]) {
        tableName = @"en-US";
    }
    return NSLocalizedStringFromTableInBundle(key, tableName, bundle, nil);
}


@implementation EMAI18n

#pragma mark - 本地化字符串

+ (NSString *)LittleApp_UserInfoPermission_BluetoothPermDesc { return stringForKey(@"Evw"); }
+ (NSString *)LittleApp_UserInfoPermission_BluetoothPermListDisplay { return stringForKey(@"ka8"); }
+ (NSString *)LittleApp_UserInfoPermission_BluetoothPermName { return stringForKey(@"qTc"); }
+ (NSString *)LittleApp_UserInfoPermission_BluetoothPermNameFull { return stringForKey(@"6/c"); }
+ (NSString *)add_address { return stringForKey(@"sAE"); }
+ (NSString *)address_already_exists { return stringForKey(@"XUQ"); }
+ (NSString *)app_update_tip { return stringForKey(@"GZQ"); }
+ (NSString *)brightness { return stringForKey(@"k94"); }
+ (NSString *)change_address { return stringForKey(@"80w"); }
+ (NSString *)contact { return stringForKey(@"adE"); }
+ (NSString *)continue_show_modal_exit { return stringForKey(@"Y1U"); }
+ (NSString *)continue_show_modal_no { return stringForKey(@"zuI"); }
+ (NSString *)continue_show_modal_tip { return stringForKey(@"ym0"); }
+ (NSString *)date_format_incorrect { return stringForKey(@"f6U"); }
+ (NSString *)detailed_address { return stringForKey(@"0I8"); }
+ (NSString *)device_info_desc { return stringForKey(@"s4g"); }
+ (NSString *)device_info_name { return stringForKey(@"CEM"); }
+ (NSString *)docs_nothing_found { return stringForKey(@"rA4"); }
+ (NSString *)docs_people_may_mention { return stringForKey(@"cHk"); }
+ (NSString *)docs_toolbar_high_light { return stringForKey(@"50k"); }
+ (NSString *)enter_bot { return stringForKey(@"Eos"); }
+ (NSString *)enter_detailed_address_information { return stringForKey(@"Dfk"); }
+ (NSString *)failed_to_connect_ide { return stringForKey(@"ghk"); }
+ (NSString *)get_address_failed { return stringForKey(@"FFo"); }
+ (NSString *)load_failed_and_retry { return stringForKey(@"rqI"); }
+ (NSString *)my_address { return stringForKey(@"Mr4"); }
+ (NSString *)name { return stringForKey(@"jaE"); }
+ (NSString *)no_internet_connection { return stringForKey(@"/58"); }
+ (NSString *)not_logged_in { return stringForKey(@"F+Y"); }
+ (NSString *)open_with_other_app { return stringForKey(@"sLc"); }
+ (NSString *)phone_number { return stringForKey(@"org"); }
+ (NSString *)phone_number_invalid { return stringForKey(@"fQQ"); }
+ (NSString *)please_select { return stringForKey(@"peg"); }
+ (NSString *)please_wait { return stringForKey(@"1II"); }
+ (NSString *)select_region { return stringForKey(@"DtQ"); }
+ (NSString *)share_fail { return stringForKey(@"1lQ"); }
+ (NSString *)show_prompt_ok { return stringForKey(@"uYk"); }
+ (NSString *)show_prompt_placeholder { return stringForKey(@"NOg"); }
+ (NSString *)submission_failed { return stringForKey(@"eZA"); }
+ (NSString *)sure_to_test_on_device { return stringForKey(@"a+o"); }
+ (NSString *)update_now { return stringForKey(@"R1g"); }

@end
