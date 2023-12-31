//
//  IESEffectRecord.h
//  EffectPlatformSDK-Pods
//
//  Created by pengzhenhuan on 2020/9/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectRecord : NSObject

@property (nonatomic, copy, readonly) NSString *effectMD5; // Primary property

@property (nonatomic, copy, readonly) NSString *effectIdentifier;

@property (nonatomic, assign, readonly) unsigned long long size;

@property (nonatomic, copy, readonly) NSString *panel;

- (instancetype)initWithEffectMD5:(NSString *)effectMD5
                 effectIdentifier:(NSString *)effectIdentifier
                             size:(unsigned long long)size;

- (instancetype)init NS_UNAVAILABLE;

- (void)updatePanelName:(NSString *)panel;

@end


NS_ASSUME_NONNULL_END
