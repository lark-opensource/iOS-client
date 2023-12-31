//
//  BDTuring+TTNet.h
//  BDTuring
//
//  Created by bob on 2021/8/2.
//

#import "BDTuring.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuring (TTNet)

/// the path will not be block by BDTuring
@property (nonatomic, copy, nullable) NSArray<NSString *> *skipPathList;

/*! @abstract  if you use TTNetworkManager for all the network task and
 want to handle captcha automatically besides automatically retry request, you should call this method after turing setup
*/
- (void)setupProcessorForTTNetworkManager;

@end

NS_ASSUME_NONNULL_END
