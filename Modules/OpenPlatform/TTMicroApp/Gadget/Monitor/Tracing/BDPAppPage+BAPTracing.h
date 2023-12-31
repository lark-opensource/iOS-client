//
//  BDPAppPage+BAPTracing.h
//  Timor
//
//  Created by Chang Rong on 2020/2/17.
//

#import <Foundation/Foundation.h>
#import "BDPAppPage.h"
#import <OPFoundation/BDPTracing.h>

NS_ASSUME_NONNULL_BEGIN

///  非BDPAppPage请勿调用这里的方法
@interface BDPAppPage(BAPTracing)

@property (nonatomic, strong, readonly) BDPTracing *bap_trace;

- (void)bap_bindTracing:(BDPTracing *)trace;

@end

NS_ASSUME_NONNULL_END
