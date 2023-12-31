//
//  BDPPermissionViewControllerDelegate.h
//  OPFoundation
//
//  Created by justin on 2022/12/23.
//

#import <UIKit/UIKit.h>
#import "BDPBasePluginDelegate.h"
#import "OPAppUniqueID.h"

// FROM: BDPPermissionViewController.h
typedef void(^BDPPermissionViewControllerAction)(NSArray<NSNumber *> * _Nonnull authorizedScopes, NSArray<NSNumber *> * _Nonnull deniedScopes);

NS_ASSUME_NONNULL_BEGIN

@protocol BDPPermissionViewControllerDelegate <BDPBasePluginDelegate>

@required

@property (nonatomic, copy) BDPPermissionViewControllerAction completion;

+ (UIViewController<BDPPermissionViewControllerDelegate> *)initControllerWithName:(NSString *)name
                        icon:(NSString *)icon
                    uniqueID:(OPAppUniqueID *)uniqueID
                  authScopes:(NSDictionary<NSString *, NSDictionary *> *)authScopes
                   scopeList:(NSArray<NSNumber *> *)scopeList;

@end

NS_ASSUME_NONNULL_END
