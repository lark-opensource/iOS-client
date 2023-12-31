//
//  TSPKDetectTrigger.h
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import <Foundation/Foundation.h>

#import "TSPKDetectEvent.h"
#import "TSPKDetectCondition.h"

@class TSPKEvent;

typedef void(^TSPKTriggerDetectAction)(TSPKDetectEvent *_Nonnull);

@interface TSPKDetectTrigger : NSObject

@property (nonatomic, copy, nonnull) NSString *interestAPIType;
@property (nonatomic, copy, nonnull) TSPKTriggerDetectAction detectAction;

- (instancetype _Nullable)initWithParams:(NSDictionary *_Nonnull)params apiType:(NSString *_Nonnull)apiType;

- (void)updateWithParams:(NSDictionary *_Nonnull)params;


- (BOOL)canHandelEvent:(TSPKEvent *_Nonnull)event;

@end


