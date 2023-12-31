//
//  BDIRPCRequest.h
//  BDiOSpy
//
//  Created by byte dance on 2021/11/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDIRPCRequest : NSObject

@property(nonatomic, assign) int reqId;
@property(nonatomic, strong) NSDictionary *params;
@property(nonatomic, copy) NSString *method;

+ (instancetype)instantiateWithPayload:(NSDictionary *)payloadDict;

@end

NS_ASSUME_NONNULL_END
