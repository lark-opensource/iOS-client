//
//  UIViewController+Picker.m
//  Applog
//
//  Created by bob on 2019/3/7.
//

#import "UIViewController+Picker.h"
#import "BDPickerConstants.h"

#import "BDPickerDependency.h"

@implementation UIViewController (Picker)

- (NSDictionary *)bd_pickerInfo {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    NSString *page = NSStringFromClass([self class]);
    [info setValue:page forKey:kBDPickerPageKey];

    return info;
}

@end
