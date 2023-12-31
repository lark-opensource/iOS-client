//
//  BDAccountSealer+Theme.m
//  BDTuring
//
//  Created by bob on 2020/7/2.
//

#import "BDAccountSealer+Theme.h"
#import "BDTuringUIHelper.h"
#import "BDTuringMacro.h"

@implementation BDAccountSealer (Theme)

+ (void)setCustomTheme:(NSDictionary *)theme {
    [BDTuringUIHelper sharedInstance].sealThemeDictionary = theme;
}

+ (void)setCustomText:(NSDictionary *)text {
    [BDTuringUIHelper sharedInstance].sealTextDictionary = text;
}

@end
