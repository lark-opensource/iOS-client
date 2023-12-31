//
//  ACCRecorderTextModeViewModel.h
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/11/4.
//

#import <CreationKitArch/ACCRecorderViewModel.h>
#import "ACCTextModeService.h"

@interface ACCRecorderTextModeViewModel : ACCRecorderViewModel<ACCTextModeService>

- (void)send_textModeVCDidAppearSignal;

@end
