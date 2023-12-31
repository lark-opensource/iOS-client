//
//  BDTuringAlertOption+Creator.m
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDTuringAlertOption+Creator.h"
#import "BDTuringPiperConstant.h"
#import "NSDictionary+BDTuring.h"
#import "BDAccountSealConstant.h"
#import "BDTuringMacro.h"
#import "BDTuringUtility.h"

@implementation BDTuringAlertOption (Creator)

@dynamic title;
@dynamic optionDictionary;
@dynamic callback;

+ (NSArray<BDTuringAlertOption *> *)optionsWithArray:(NSArray *)parameter
                                            callback:(BDTuringPiperOnCallback)callback {
    NSMutableArray<BDTuringAlertOption *> *options = [NSMutableArray new];
    for (NSDictionary *option in parameter) {
        if (!BDTuring_isValidDictionary(option)) {
            continue;
        }
        
        NSString *title = [option turing_stringValueForKey:kBDAccountSealAlertTitle];
        BDTuringAlertOption *o = [BDTuringAlertOption new];
        o.title = title;
        o.optionDictionary = option;
        o.callback = callback;
        [options addObject:o];
    }
    
    return options;
}

@end
