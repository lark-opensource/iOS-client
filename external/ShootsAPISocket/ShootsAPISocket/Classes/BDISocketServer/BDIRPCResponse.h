//
//  BDIRPCResponse.h
//  BDiOSpy
//
//  Created by byte dance on 2021/11/22.
//

#import <Foundation/Foundation.h>
#import "BDIRPCStatus.h"
#import "BDIRPCRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDIRPCResponse : NSObject

@property(nonatomic, assign) int rspId;
@property(nonatomic, strong) id result;
@property(nonatomic, strong) NSDictionary *error;

+ (instancetype)responseToRequest:(BDIRPCRequest *)request WithResult:(id)result;
+ (instancetype)responseErrorWithStatus:(BDIRPCStatus *)status;
+ (instancetype)responseErrorTo:(BDIRPCRequest *)request WithStatus:(BDIRPCStatus *)status;
+ (instancetype)responsePushMessage:(id)message;

- (NSDictionary *)JSON;

@end

NS_ASSUME_NONNULL_END
