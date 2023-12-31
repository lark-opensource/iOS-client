//
//  ACCRecordMode+UploadButton.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/11/30.
//

#import "ACCRecordMode+UploadButton.h"
#import <CreationKitInfra/ACCModuleService.h>

@implementation ACCRecordMode (UploadButton)

- (BOOL)shouldShowBubble
{
    return ACCRecordModeTakePicture == self.modeId
    || ACCRecordModeMixHoldTapRecord == self.modeId
    || ACCRecordModeMixHoldTapLongVideoRecord == self.modeId;
}

@end
