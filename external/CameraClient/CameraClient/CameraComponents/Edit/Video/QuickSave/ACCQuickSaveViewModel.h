//
//  ACCQuickSaveViewModel.h
//  CameraClient-Pods-Aweme
//
//  Created by ZZZ on 2021/5/12.
//

#import "ACCEditViewModel.h"
#import "ACCQuickSaveService.h"

@interface ACCQuickSaveViewModel : ACCEditViewModel <ACCQuickSaveService>

- (void)notifywillTriggerQuickSaveAction;

@end
