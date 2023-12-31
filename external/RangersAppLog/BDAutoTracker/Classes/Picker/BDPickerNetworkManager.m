//
//  BDPickerNetworkManager.m
//  Applog
//
//  Created by bob on 2019/1/20.
//

#import "BDPickerNetworkManager.h"
#import "BDTrackerCoreConstants.h"

#import "BDAutoTrackDeviceHelper.h"
#import "BDAutoTrackServiceCenter.h"
#import "BDAutoTrackLocalConfigService.h"
#import "BDAutoTrackNetworkRequest.h"
#import "BDAutoTrackUtility.h"
#import "BDAutoTrackURLHostProvider.h"
#import "NSDictionary+VETyped.h"

NSString * bd_picker_responseMessage(NSDictionary *response) {
    if ([response isKindOfClass:[NSDictionary class]] && response.count > 0) {
        return [response vetyped_stringForKey:@"message"];
    }

    return nil;
}

void bd_picker_add_common(NSMutableDictionary *header) {
    [header setValue:@(BDAutoTrackerSDKVersion) forKey:kBDPickerSDKVersion];
    CGSize resolution = [[UIScreen mainScreen] bounds].size;
    [header setValue:@((int)(resolution.width)) forKey:@"width"];
    [header setValue:@((int)(resolution.height)) forKey:@"height"];

}
