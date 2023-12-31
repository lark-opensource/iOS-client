//
//  BDTuringAlertOption.h
//  BDTuring
//
//  Created by bob on 2020/7/13.
//

#import "BDAccountSealDefine.h"

NS_ASSUME_NONNULL_BEGIN

/*
 BDTuringAlertOption for custom alert user interface
 e.g.
 
 UIAlertAction *action = [UIAlertAction actionWithTitle:option.title
    style:UIAlertActionStyleDefault
    handler:^(UIAlertAction * action) {
     [option triggerAction];
 }];
 */
@interface BDTuringAlertOption : NSObject

/// the option title
@property (nonatomic, copy, readonly) NSString *title;

/// trigger action, you can only trigger once!
- (void)triggerAction;

@end

NS_ASSUME_NONNULL_END
