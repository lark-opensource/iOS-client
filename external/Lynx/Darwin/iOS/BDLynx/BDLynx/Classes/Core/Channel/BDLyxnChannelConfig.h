//
//  BDLyxnChannelConfig.h
//  BDLynx
//
//  Created by  wanghanfeng on 2020/2/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BDLynxLoadChannelPolicy) {
  BDLynxLoadChannelPolicyHigh,    // 高优先级，会在应用启动时拉取
  BDLynxLoadChannelPolicyNormal,  // 默认优先级，会在一定延迟后拉取
  BDLynxLoadChannelPolicyDynamic  // 占位枚举，如需动态拉取，调用实现BDLynxGurdModuleProtocol的相应方法即可
};

@interface BDLynxChannelRegisterConfig : NSObject

@property(nonatomic, copy) NSString *channelDescription;
@property(nonatomic, copy) NSString *channelName;
@property(nonatomic, assign) NSUInteger minTemplateVersionCode;
@property(nonatomic, assign) BDLynxLoadChannelPolicy loadPolicy;

@end

@interface BDLynxBaseConfig : NSObject

@property(nonatomic, copy) NSString *groupID;
@property(nonatomic, strong) NSURL *rootDirURL;

- (instancetype)init
    __attribute__((unavailable("init not available, call initWithDictionary: instead")));
- (instancetype)initWithDictionary:(NSDictionary *)dictionary groupID:(NSString *)groupID;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                           groupID:(NSString *)groupID
                           rootDir:(NSURL *)rootDir;

- (void)updateWithDictionary:(NSDictionary *)dictionary;

@end

@interface BDLynxTemplateConfig : BDLynxBaseConfig

@property(nonatomic, copy) NSString *cardID;
@property(nonatomic, copy) NSString *cardPath;
@property(nonatomic, copy) NSString *cardVersion;
@property(nonatomic, copy) NSString *desc;
@property(nonatomic, strong) NSDictionary *extra;
@property(nonatomic, assign) BOOL hasExtResource;  // 是否资源预加载
@property(nonatomic, copy) NSArray *extURLPrefix;  // 预加载资源前缀

- (NSURL *)realURLForPath:(NSString *)path;
- (NSData *)dataForPath:(NSString *)path;

@end

@interface BDLynxChannelIOSConfig : BDLynxBaseConfig

@property(nonatomic, copy) NSArray<BDLynxTemplateConfig *> *templateList;

- (BDLynxTemplateConfig *)templateConfigForCardID:(NSString *)cardID;

@end

@interface BDLyxnChannelConfig : BDLynxBaseConfig

@property(nonatomic, copy) NSString *version;
@property(nonatomic, strong) BDLynxChannelIOSConfig *iOSConfig;

@end

NS_ASSUME_NONNULL_END
