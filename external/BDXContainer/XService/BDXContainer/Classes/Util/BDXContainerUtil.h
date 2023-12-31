//
//  BDXContainerUtil.h
//  BDXContainer
//
//  Created by xinwen tan on 2021/4/7.
//

#import <BDXServiceCenter/BDXViewContainerProtocol.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXContainerUtil : NSObject

+ (nullable UIViewController<BDXContainerProtocol> *)topBDXViewController;

@end

NS_ASSUME_NONNULL_END
