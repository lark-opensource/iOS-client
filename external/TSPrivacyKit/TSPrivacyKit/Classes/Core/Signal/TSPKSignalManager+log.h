//
//  TSPKSignalManager+log.h
//  Musically
//
//  Created by ByteDance on 2022/12/20.
//

#import "TSPKSignalManager.h"

@interface TSPKSignalManager (log)

+ (void)addLogWithTag:(nullable NSString *)tag content:(nullable NSString *)content;

@end
