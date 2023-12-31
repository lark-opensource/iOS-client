//
//  TTKitchenEditorViewController.h
//  Pods
//
//  Created by SongChai on 2018/4/18.
//

#import <UIKit/UIKit.h>
#import "TTKitchenAddition.h"

extern NSNotificationName const kTTKitchenEditorSuccessNotification;
@interface TTKitchenEditorViewController : UIViewController

- (instancetype)initWithKitchenModel:(TTKitchenModel *)kitchenModel;

@end
