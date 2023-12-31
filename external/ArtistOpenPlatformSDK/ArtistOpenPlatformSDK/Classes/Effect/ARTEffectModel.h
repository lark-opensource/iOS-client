//
//  ARTEffectModel.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/10/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ARTEffectPrototype <NSObject>
@required
-(NSString * _Nonnull)effectName;
-(NSString * _Nonnull)effectIdentifier;
-(NSString * _Nonnull)resourceID;
-(NSString * _Nonnull)md5;
-(NSArray<NSString *> *_Nonnull)fileDownloadURLs;
@end

@interface ARTEffectModel : NSObject<ARTEffectPrototype>

@property (nonatomic, copy, readonly, nonnull) NSString *effectName;
@property (nonatomic, copy, readonly, nonnull) NSString *effectIdentifier;
@property (nonatomic, copy, readonly, nonnull) NSString *resourceID;
@property (nonatomic, copy, readonly, nonnull) NSArray<NSString *> *fileDownloadURLs;
@property (nonatomic, copy, readonly, nonnull) NSString *md5;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithName:(NSString *)effectName
            effectIdentifier:(NSString *)effectIdentifier
                  resourceID:(NSString *)resourceID
            fileDownloadURLs:(NSArray<NSString *> *)fileDownloadURLs
                         md5:(NSString *)md5;

@end

NS_ASSUME_NONNULL_END
