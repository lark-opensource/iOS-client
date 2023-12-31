//
//  BDTuringAlertOption.m
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDTuringAlertOption.h"
#import "BDTuringPiperConstant.h"

@interface BDTuringAlertOption ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSDictionary *optionDictionary;
@property (nonatomic, strong) BDTuringPiperOnCallback callback;

@end

@implementation BDTuringAlertOption

- (void)triggerAction {
    BDTuringPiperOnCallback callback = self.callback;
    if (callback == nil) {
        return;
    }
    NSDictionary *optionDictionary = self.optionDictionary.copy;
    dispatch_async(dispatch_get_main_queue(), ^{
        callback(BDTuringPiperMsgSuccess, optionDictionary);
    });
    
    self.callback = nil;
}

@end
