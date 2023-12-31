//
//  BDTuringIdentityModel.h
//  BDTuring
//
//  Created by bob on 2020/6/30.
//

#import "BDTuringVerifyModel.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 the callback is work with BDTuringIdentityResult
 e.g.
 
 BDTuringVerifyResultCallback callback = ^(BDTuringVerifyResult * verify) {
     BDTuringIdentityResult *result = (BDTuringIdentityResult *)verify;
/// now you will get BDTuringIdentityResult
 };
 
 BDTuringIdentityModel *model = [BDTuringIdentityModel new];
 model.callback
 */
@interface BDTuringIdentityModel : BDTuringVerifyModel

/*! @abstract property for request
 */
@property (nonatomic, copy, nullable) NSString *scene;
@property (nonatomic, copy) NSString *ticket;
@property (nonatomic, assign) NSInteger mode;

/// if exist, you can tell the model
@property (nonatomic, weak, nullable) UIViewController *currentViewController;
@property (nonatomic, weak, nullable) UINavigationController *currentNavigator;

@end

NS_ASSUME_NONNULL_END
