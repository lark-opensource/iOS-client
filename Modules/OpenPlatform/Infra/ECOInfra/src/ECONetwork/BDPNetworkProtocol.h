//
//  BDPNetworkProtocol.h
//  ECOInfra
//
//  Created by bytedance on 2021/4/7.
//

#ifndef BDPNetworkProtocol_h
#define BDPNetworkProtocol_h

@protocol BDPNetworkTaskProtocol <NSObject>
- (void)cancel;
- (void)suspend;
- (void)resume;
@end

@protocol BDPNetworkResponseProtocol <NSObject>
@property (readonly) NSInteger statusCode;
@property (readonly, copy) NSDictionary *allHeaderFields;
@property (nullable, readonly, copy) NSURL *URL;
@end

@protocol BDPNetworkRequestProtocol <NSObject>

- (id<BDPNetworkTaskProtocol>)taskWithRequestUrl:(NSString *)URLString parameters:(id)parameters extraConfig:(id)extraConfig completion:(void (^)(NSError *error, id jsonObj, id<BDPNetworkResponseProtocol> response))completion;

@end


#endif /* BDPNetworkProtocol_h */
