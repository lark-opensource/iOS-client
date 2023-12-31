//
//  ACCAlertDefaultImpl.h
//  CameraClient
//
//  Created by haoyipeng on 2021/11/15.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCAlertProtocol.h>

@interface ACCUIAlertActionDefaultImpl : NSObject <ACCUIAlertActionProtocol>

@end

@interface ACCUIAlertViewDefaultImpl: UIView <ACCUIAlertViewProtocol>

@end

@interface ACCAlertDefaultImpl: NSObject <ACCAlertProtocol>

@end
