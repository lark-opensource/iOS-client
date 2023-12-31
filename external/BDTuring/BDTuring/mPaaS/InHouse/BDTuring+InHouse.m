//
//  BDTuring+InHouse.m
//  BDTuring
//
//  Created by bob on 2020/6/5.
//

#import "BDTuring+InHouse.h"
#import "BDTuring+Private.h"
#import "BDTuringSettings.h"
#import "BDTuringEventService.h"
#import "NSString+BDTuring.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringSettings+Custom.h"
#import "BDTuringCoreConstant.h"


NSString *const BDTuringBOEURLPicture           = @"https://captcha.web.bytedance.net/";
NSString *const BDTuringBOEURLSMS               = @"https://mobile.web.bytedance.net/";
NSString *const BDTuringBOEURLQA                = @"https://qa.web.bytedance.net/";
NSString *const BDTuringBOEURLSeal              = @"https://unblock.web.bytedance.net/";
NSString *const BDTuringBOEURLAutoVerify        = @"https://smart-captcha.web.bytedance.net/app/smarter";
NSString *const BDTuringBOEURLFullAutoVerify    = @"https://smart-captcha.web.bytedance.net/app/smartest";


@implementation BDTuring (InHouse)

+ (NSBundle *)inhouseBundle {
    static NSBundle *sdkBundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"BDTuringInHouseResource" withExtension:@"bundle"];
        sdkBundle = [NSBundle bundleWithURL:url];
    });

    return sdkBundle;
}

+ (NSDictionary *)inhouseCustomValueForKey:(NSString *)key {
    NSString *fakeDataPath = [[self inhouseBundle] pathForResource:key ofType:@".json"];
    NSString *fakeString = [NSString stringWithContentsOfFile:fakeDataPath
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    NSDictionary *fakeData = [fakeString turing_dictionaryFromJSONString];
    
    return fakeData;
}

@end
