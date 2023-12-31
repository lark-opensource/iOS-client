//
//  PNSUserExceptionProtocol.h
//  BDAlogProtocol
//
//  Created by ByteDance on 2022/6/27.
//

#import "PNSServiceCenter.h"

#define PNSUserException PNS_GET_INSTANCE(PNSUserExceptionProtocol)

@protocol PNSUserExceptionProtocol <NSObject>

- (void)trackUserExceptionWithType:(NSString *_Nonnull)exceptionType
                   backtracesArray:(NSArray *_Nonnull)backtraces
                      customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                           filters:(NSDictionary<NSString *, id> *_Nullable)filters
                          callback:(void (^ _Nullable)(NSError *_Nullable error))callback;

- (void)trackUserExceptionWithType:(NSString *_Nonnull)exceptionType
                             title:(NSString *_Nonnull)title
                          subTitle:(NSString *_Nullable)subTitle
                      customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                           filters:(NSDictionary<NSString *, id> *_Nullable)filters
                          callback:(void (^ _Nullable)(NSError *_Nullable error))callback;

@end

