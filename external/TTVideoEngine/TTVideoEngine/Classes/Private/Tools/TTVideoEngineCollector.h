//
//  TTVideoEngineCollector.h
//  Pods
//
//  Created by coeus on 2021/3/23.
//

#ifndef TTVideoEngineCollector_h
#define TTVideoEngineCollector_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTVideoEngineCollector : NSObject

+ (void)updatePlayConsumedSize:(int64_t)size;
+ (int64_t) getPlayConsumeSize;

@end

NS_ASSUME_NONNULL_END
#endif /* TTVideoEngineCollector_h */
