//
//  IESGurdMetadataProtocol.h
//  Pods
//
//  Created by 陈煜钏 on 2021/2/4.
//

#ifndef IESGurdMetadataProtocol_h
#define IESGurdMetadataProtocol_h

#import <IESMetadataStorage/IESMetadataProtocol.h>

@protocol IESGurdMetadataProtocol <IESMetadataProtocol>

@property (nonatomic, copy) NSString *accessKey;

@property (nonatomic, copy) NSString *channel;

@property (nonatomic, assign) uint64_t packageID;

+ (instancetype)metaWithData:(NSData *)data;

@end

#endif /* IESGurdMetadataProtocol_h */
