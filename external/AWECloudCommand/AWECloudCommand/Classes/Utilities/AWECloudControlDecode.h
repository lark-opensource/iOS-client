//
//  HTSCloudControlDecode.h
//  LiveStreaming
//
//  Created by 权泉 on 2017/2/16.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWECloudControlDecode : NSObject

+ (id)payloadWithDecryptData:(NSData *)data withKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
