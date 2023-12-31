//
//  BDXPopupContainerService.h
//  BDXContainer
//
//  Created by xinwen tan on 2021/4/8.
//

#import <BDXServiceCenter/BDXPopupContainerProtocol.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDXPopupContainerService : NSObject <BDXPopupContainerServiceProtocol>

- (BOOL)closePopup:(NSString *)containerID animated:(BOOL)animated params:(nullable NSDictionary *)params;
- (BOOL)closePopup:(NSString *)containerID animated:(BOOL)animated params:(nullable NSDictionary *)params completion:(nullable dispatch_block_t)finalCompletion;

@end

NS_ASSUME_NONNULL_END
