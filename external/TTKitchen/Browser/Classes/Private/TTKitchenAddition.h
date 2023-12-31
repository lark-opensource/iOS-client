//
//  TTKitchenAddition.h
//  Pods
//
//  Created by SongChai on 2018/4/18.
//

#import <Foundation/Foundation.h>
#import "TTKitchenInternal.h"
#import <UIKit/UIKit.h>

@interface TTKitchenModel (BrowserAddition)

- (BOOL)isSwitchOpen;
- (NSString *)text;

- (void)textFieldAction:(NSString *)text error:(NSError **)error;
- (void)switchAction;
@end
