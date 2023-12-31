//
//  ARTEffectRecord.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/11/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARTEffectRecord : NSObject
@property (nonatomic, copy, readonly) NSString *effectMD5; // Primary property

@property (nonatomic, copy, readonly) NSString *effectIdentifier;

@property (nonatomic, assign, readonly) unsigned long long size;

- (instancetype)initWithEffectMD5:(NSString *)effectMD5
                 effectIdentifier:(NSString *)effectIdentifier
                             size:(unsigned long long)size;

- (instancetype)init NS_UNAVAILABLE;
@end

NS_ASSUME_NONNULL_END
