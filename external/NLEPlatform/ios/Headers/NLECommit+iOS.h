//
//  NLECommit+iOS.h
//  Pods
//
//  Created by bytedance on 2020/12/7.
//

#ifndef NLECommit_iOS_h
#define NLECommit_iOS_h

#import <Foundation/Foundation.h>
#import "NLENode+iOS.h"

@class NLEModel_OC;

@interface NLECommit_OC : NLENode_OC

- (NSString *)getDescription;

- (void)setDescription:(NSString *)descripition;

- (int64_t)getTimeStamp;

- (void)setTimeStamp:(int64_t)timeStamp;

- (int64_t)getVersion;

- (void)setVersion:(int64_t)version;

- (NLEModel_OC*)getModel;

@end

#endif /* NLECommit_iOS_h */
