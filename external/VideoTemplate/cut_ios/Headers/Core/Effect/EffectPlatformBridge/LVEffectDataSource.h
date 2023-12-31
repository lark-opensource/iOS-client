//
//  IESEffectDataSource.h
//  Pods
//
//  Created by wuweixin on 2020/10/21.
//


#import <Foundation/Foundation.h>

#ifndef LVEffectDataSource_h
#define LVEffectDataSource_h

typedef NS_ENUM(NSInteger, LVEffectSourcePlatform) {
    LVEffectSourcePlatformLoki = 0, // 默认Loki平台
    LVEffectSourcePlatformArtist, // 艺术家开放平台
};

@protocol LVEffectPrototype <NSObject>
@required
-(NSString * _Nonnull)effectName;
-(NSString * _Nonnull)effectIdentifier;
-(NSString * _Nonnull)resourceID;
-(NSString * _Nonnull)md5;
-(NSArray<NSString *> *_Nonnull)fileDownloadURLs;

-(NSString *_Nullable)downloadFilePath;
@end

@protocol LVEffectDataSource<NSObject>
@required
-(LVEffectSourcePlatform)effectSourcePlatform;
-(id<LVEffectPrototype> _Nonnull)effectModel;
@end

#endif /* IESEffectDataSource_h */
