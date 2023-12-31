//
//  PNSPolicyDecisionProtocol.h
//  PNSServiceKit
//
//  Created by PengYan on 2022/11/14.
//

#import <Foundation/Foundation.h>

#import "PNSRuleEngineProtocol.h"

@protocol PNSPDPResultProtocol <NSObject>

@property (nonatomic) BOOL success;
@property (nonatomic, copy, nullable) NSError *error;
@property (nonatomic, strong, nullable) id<PNSRuleResultProtocol> result;

@end

@protocol PNSPolicyDecisionProtocol <NSObject>

/// sync validate request protocol, implement in unify validate manager
/// - Parameters:
///   - source: "BPEA" or "Guard"
///   - entryToken: token stands for API, search this token in MSC platform
///   - context: context params used to validate
///   - wrappedAPI: API to execute if validate success
- (id<PNSPDPResultProtocol> _Nullable)validatePolicyWithSource:(NSString * _Nonnull)source
                                                    entryToken:(NSString * _Nonnull)entryToken
                                                       context:(NSDictionary * _Nullable)context
                                                    wrappedAPI:(dispatch_block_t _Nullable)wrappedAPI;

@end
