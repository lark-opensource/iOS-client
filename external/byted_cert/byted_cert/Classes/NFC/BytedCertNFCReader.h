//
//  BytedCertNFCReader.h
//  byted_cert
//
//  Created by liuminghui.2022 on 2023/4/10.
//

#import <Foundation/Foundation.h>
#import <byted_cert/JLReader.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BytedCertNFCErrorType) {
    BytedCertNFCErrorNFCUnOpen = 1001, //NFC未开启
};


@interface BytedCertNFCReader : NSObject

- (void)startNFCWithParams:(NSDictionary *)params connectBlock:(void (^_Nullable)(JLConnectTagState connectState))connectBlock completion:(void (^)(NSDictionary *_Nonnull))completion;

@end

NS_ASSUME_NONNULL_END
