//
//  BDIRPCRoute.h
//  BDiOSpy
//
//  Created by byte dance on 2021/11/19.
//

#import <Foundation/Foundation.h>
#import "BDIRPCResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDIRPCRoute : NSObject

@property (nonatomic, copy) NSString *api;

@property (nonatomic, strong) id target;
@property (nonatomic, assign) SEL action;

+ (instancetype)CALL:(NSString *)api respondTarget:(id)target action:(SEL)action;
- (BDIRPCResponse *)dispatchJsonRpcRequest:(BDIRPCRequest *)request;

@end

NS_ASSUME_NONNULL_END
