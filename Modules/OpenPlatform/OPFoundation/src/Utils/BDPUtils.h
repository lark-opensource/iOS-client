//
//  BDPUtils.h
//  Timor
//
//  Created by MacPu on 2019/1/2.
//

#import <UIKit/UIKit.h>
#import <ECOInfra/BDPLog.h>
#import "BDPMacroUtils.h"
#import <ECOInfra/BDPUtils.h>

/// Execute the specified block with tracing.
/// this will execute immediately
FOUNDATION_EXPORT void BDPExecuteTracing(dispatch_block_t _Nullable block);

/// Execute the specified block on the main queue. Unlike dispatch_async()
/// this will execute immediately if we're already on the main queue.
FOUNDATION_EXTERN void BDPExecuteOnMainQueue(dispatch_block_t _Nullable block);

/// Execute the specified block on the global queue. Unlike dispatch_async()
/// this will execute immediately if we're not already on the main queue.
FOUNDATION_EXTERN void BDPExecuteOnGlobalQueue(dispatch_block_t _Nullable block);

/// Legacy function to execute the specified block on the main queue synchronously.
/// ⚠️ Please do not use this unless you know what you're doing.
FOUNDATION_EXTERN void BDPExecuteOnMainQueueSync(dispatch_block_t _Nullable block);

/// Returns the decode data from path that encrypted by uglify coder.h
FOUNDATION_EXTERN NSData * _Nullable BDPDecodeDataFromPath(NSString * _Nullable filePath);

/// Returns Current Network Type
FOUNDATION_EXTERN NSString * _Nonnull BDPCurrentNetworkType(void);

/// Returns Current Network is Connected or not
FOUNDATION_EXTERN BOOL BDPCurrentNetworkConnected(void);
