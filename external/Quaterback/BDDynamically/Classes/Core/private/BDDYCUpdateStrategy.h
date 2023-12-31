//
//  BDDYCUpdateStrategy.h
//  BDDynamically
//
//  Created by zuopengliu on 10/10/18.
//

#import <Foundation/Foundation.h>



NS_ASSUME_NONNULL_BEGIN

#if BDAweme
__attribute__((objc_runtime_name("AWECFButtercups")))
#elif BDNews
__attribute__((objc_runtime_name("TTDCactus")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDHippopotamus")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDButterHead")))
#endif
@interface BDDYCUpdateStrategy : NSObject

- (instancetype)initWithUpdateNotifier:(void (^)(void))handler;

@end

NS_ASSUME_NONNULL_END
