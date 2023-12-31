//
//  BDPPermissionViewController.h
//  Timor
//
//  Created by liuxiangxin on 2019/6/13.
//

#import <UIKit/UIKit.h>
#import <OPFoundation/BDPPermissionScope.h>
#import <OPFoundation/BDPJSBridgeProtocol.h>
#import <OPFoundation/BDPPermissionViewControllerDelegate.h>

// 迁移到：OPFoundation 的 BDPPermissionViewController.h 中
//typedef void(^BDPPermissionViewControllerAction)(NSArray<NSNumber *> * _Nonnull authorizedScopes, NSArray<NSNumber *> * _Nonnull deniedScopes);

NS_ASSUME_NONNULL_BEGIN

@interface BDPPermissionViewController : UIViewController<BDPPermissionViewControllerDelegate>

@property (nonatomic, copy) BDPPermissionViewControllerAction completion;

- (instancetype)initWithName:(NSString *)name
                        icon:(NSString *)icon
                    uniqueID:(OPAppUniqueID *)uniqueID
                  authScopes:(NSDictionary<NSString *, NSDictionary *> *)authScopes
                   scopeList:(NSArray<NSNumber *> *)scopeList;

@end

NS_ASSUME_NONNULL_END
