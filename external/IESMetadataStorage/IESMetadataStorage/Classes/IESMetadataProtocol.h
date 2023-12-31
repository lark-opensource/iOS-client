//
//  IESMetadataProtocol.h
//  Pods
//
//  Created by 陈煜钏 on 2021/1/26.
//

#ifndef IESMetadataProtocol_h
#define IESMetadataProtocol_h

@protocol IESMetadataProtocol <NSObject>

@required
- (NSData *)binaryData;

- (NSString *)metadataIdentity;

@end

#endif /* IESMetadataProtocol_h */
