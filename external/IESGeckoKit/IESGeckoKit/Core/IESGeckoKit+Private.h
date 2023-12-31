//
//  IESGurdKit+Private.h
//  IESGurdKit
//
//  Created by li keliang on 2019/3/1.
//

#import "IESGeckoKit.h"

NS_ASSUME_NONNULL_BEGIN

#define IESGurdKitInstance      [IESGurdKit sharedInstance]

@interface IESGurdLowStorageData : NSObject

@property (nonatomic, copy) NSArray<NSString *> *groups;

@property (nonatomic, copy) NSArray<NSString *> *channels;

@end

@interface IESGurdKit ()

+ (instancetype)sharedInstance;

@property (nonatomic, copy) NSString *appId;

@property (nonatomic, copy) NSString *appVersion;

@property (nonatomic, copy) NSString *deviceID;

@property (nonatomic, copy) NSString *(^getDeviceID)(void);

@property (nonatomic, copy) NSString *domain;

@property (nonatomic, copy) NSString *schema;

@property (nonatomic, assign) IESGurdEnvType env;

@property (atomic, strong) id<IESGurdNetworkDelegate> networkDelegate;

@property (nonatomic, strong) id<IESGurdDownloaderDelegate> downloaderDelegate;

@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *(^requestHeaderFieldBlock)(void);

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber*> *lockChannels;

@property (nonatomic, strong) NSMutableDictionary<NSString *, IESGurdLowStorageData *> *lowStorageWhiteList;

@end

NS_ASSUME_NONNULL_END
