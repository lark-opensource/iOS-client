//
//  BDXPopupViewController.h
//  BDX-Pods-Aweme
//
//  Created by bill on 2020/9/21.
//

#import <BDXServiceCenter/BDXPopupContainerProtocol.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXPopupViewController : UIViewController <BDXPopupContainerProtocol>

- (BOOL)close:(nullable NSDictionary *)params;
- (BOOL)close:(nullable NSDictionary *)params completion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
