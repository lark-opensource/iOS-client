//
//  HMDOrderFileTracer.h
//  Heimdallr
//
//  Created by maniackk on 2021/11/15.
//

#import <Foundation/Foundation.h>


@interface HMDOrderFileTracer : NSObject

+ (nonnull instancetype)sharedInstance;

- (void)startTracer;
- (void)stopTracer;

@end

