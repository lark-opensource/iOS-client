//
//  BDXNavigationBarProvider.h
//  BDXContainer
//
//  Created by tianbaideng on 2021/4/27.
//

#import <Foundation/Foundation.h>
#import <BDXServiceCenter/BDXPageContainerProtocol.h>
#import "BDXNavigationBar.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXDefaultNavigationBar : BDXNavigationBar<BDXNavigationBarProtocol>

@property (nonatomic, weak) UIViewController<BDXPageContainerProtocol> *container;

@end

NS_ASSUME_NONNULL_END
