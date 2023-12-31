//
//  SSLocalModel.h
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/7/23.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>
#import <OPFoundation/BDPUniqueID.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SSLocalType) {
    SSLocalTypeOpen,
    SSLocalTypeLog,
};

extern NSString * const kBdpLaunchQueryKey;
extern NSString * const kBdpLaunchRequestAbilityKey;
extern NSString * const kBdpLeastVersion;
extern NSString * const kBdpRelaunch;
extern NSString * const kBdpRelaunchPath;
extern NSString * const kVersionId;
extern NSString * const kVersionType;
extern NSString * const kToken;
extern NSString * const kIsDev;
extern NSString * const kBdpXScreenMode;
extern NSString * const kBdpXScreenStyle;
extern NSString * const kBdpXScreenChatID;
extern NSString * const kOpenInTemporay;
extern NSString * const kLauncherFrom;

/// 新容器上线后废弃
@interface SSLocalModel : NSObject

@property (nonatomic, assign) SSLocalType type;
@property (nonatomic, copy) NSString *app_id;
@property (nonatomic, assign) NSInteger isdev;
@property (nonatomic, copy) NSString *start_page;
@property (nonatomic, copy, readonly) NSString *start_page_no_query;
@property (nonatomic, copy) NSString *refererInfo;
@property (nonatomic, copy) NSString *useCache;
@property (nonatomic, copy) NSString *bdp_launch_query;
@property (nonatomic, copy) NSString *required_launch_ability;
@property (nonatomic, assign) NSInteger scene;
@property (nonatomic, assign) OPAppVersionType versionType;
@property (nonatomic, copy) NSString *ws_for_debug;
@property (nonatomic, copy, readonly) NSString *leastVersion;
@property (nonatomic, copy) NSString *relaunch;
@property (nonatomic, copy) NSString *relaunchPath;

/// 半屏模式
@property (nonatomic, copy, nullable) NSString *XScreenMode;

/// 半屏高度,对应链接的参数key为panel_style. 枚举类型 low medium high，默认值 high
@property (nonatomic, copy, nullable) NSString *XScreenStyle;

/// 群开放业务下的特定参数，用于业务获取当前群id
@property (nonatomic, copy, nullable) NSString *chatID;

@property (nonatomic, copy) NSString *versionId;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSString *ideDisableDomainCheck;  /**< web-view安全域名调试*/

-(void)updateLeastVersionIfExisted:(NSDictionary *)params;

- (instancetype)initWithURL:(NSURL *)url;
- (NSURL * _Nullable)generateURL;

- (BDPUniqueID *)uniqueID;

@end

NS_ASSUME_NONNULL_END

