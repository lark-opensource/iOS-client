//
//  BDXViewController.h
//  BDXContainer
//
//  Created by bill on 2021/3/14.
//

#import <UIKit/UIKit.h>

#import <BDXServiceCenter/BDXPageContainerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXPageContainerService : NSObject <BDXPageContainerServiceProtocol>

@end

@interface BDXViewController : UIViewController <BDXPageContainerProtocol>

@end

NS_ASSUME_NONNULL_END
