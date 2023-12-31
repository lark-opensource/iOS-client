//
//  TSPKSubscriber.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/19.
//

#import "TSPKHandleResult.h"

#ifndef TSPKSubscriber_h
#define TSPKSubscriber_h

@class TSPKEvent;

@protocol TSPKSubscriber <NSObject>

- (NSString * _Nonnull)uniqueId;

- (BOOL)canHandelEvent:(TSPKEvent * _Nonnull)event;

- (TSPKHandleResult * _Nullable)hanleEvent:(TSPKEvent * _Nonnull)event;

@end


#endif /* TSPKSubscriber_h */
