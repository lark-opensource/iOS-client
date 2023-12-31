//
//  TTVideoEngineEventOneErrorProtocol.h
//  Pods
//
//  Created by chibaowang on 2020/1/2.
//

#ifndef TTVideoEngineEventOneErrorProtocol_h
#define TTVideoEngineEventOneErrorProtocol_h

#import "TTVideoEngineEventBase.h"

@protocol TTVideoEngineEventOneErrorProtocol <NSObject>

- (instancetype)initWithEventBase:(TTVideoEngineEventBase*)base;

- (void)showedFirstFrame;

- (void)moviePlayRetryWithError:(NSError *)error strategy:(TTVideoEngineRetryStrategy)strategy apiver:(TTVideoEnginePlayAPIVersion)apiver;

- (void)errorHappened:(NSError*)error;

- (void)errorStatusHappened:(NSInteger)status;

@end

#endif /* TTVideoEngineEventOneErrorProtocol_h */
