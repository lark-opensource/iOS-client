//
//  BDPSchema.h
//  Timor
//
//  Created by liubo on 2019/3/11.
//

#import <UIKit/UIKit.h>
#import "OPAppUniqueID.h"
#import "BDPModuleEngineType.h"

#pragma mark - BDPSchemaVersion

/**
 * @brief Schame的版本.
 * @note BDPSchemaVersionV00: 最原始版本(占位使用,BDPSchema类不单独支持,与BDPSchemaVersionV01实现一致)
 * @note BDPSchemaVersionV01: 1.增加bdp_log字段,埋点通用参数增加bdp_log内容(包含location和bizLocation); 2.launch_from和ttid优先取bdp_log内,其次取原始schema中的;
 * @note BDPSchemaVersionV02: 1.支持版本参数; 2.增加校验和验证; 3.query改为传JSON字符串,不再decode; 4.废弃对URL字段的使用;
 */
extern NSString * const BDPSchemaVersionV00;
extern NSString * const BDPSchemaVersionV01;
extern NSString * const BDPSchemaVersionV02;

#pragma mark - BDPSchema

/// 小程序Schema解析类
@interface BDPSchema : NSObject<NSCopying>

#pragma mark - Origin

///Schame的版本.
@property (nonatomic, readonly, nullable) NSString *schemaVersion;

///原始的URL.(注意:通过BDPSchema类update特定属性不会同步修改originURL的内容)
@property (nonatomic, readonly, nullable) NSURL *originURL;
///原始的QueryParams.(注意:通过BDPSchema类update特定属性不会同步修改originQueryParams的内容)
@property (nonatomic, readonly, nullable) NSDictionary *originQueryParams;

#pragma mark - Basic

///宿主schema.(如: 本地测试sslocal, 头条正式版snssdk141, 头条测试版snssdk147, 抖音snssdk1128等)
@property (nonatomic, readonly, nullable) NSString *protocol;
///host类型.
@property (nonatomic, readonly, nullable) NSString *host;
///完整的host类型,包含segment段.
@property (nonatomic, readonly, nullable) NSString *fullHost;

#pragma mark - App

// TODO: yinyuan 这里的类型在 H5 小程序场景下会错，看下怎么办
///app类型.
@property (nonatomic, readonly) BDPType appType;
///小程序或者小游戏的ID.
@property (nonatomic, readonly, nullable) NSString *appID;

#pragma mark - Version

///版本类别.(BDPSchemaVersionV02使用)
@property (nonatomic, assign, readonly) OPAppVersionType versionType;
///开发者本次预览的token.(BDPSchemaVersionV02使用)
@property (nonatomic, readonly, nullable) NSString *token;

#pragma mark - uniqueID
- (OPAppUniqueID * _Nonnull)uniqueID;

#pragma mark - Meta

///小程序或者小游戏的meta.
@property (nonatomic, readonly) NSDictionary *meta;
///小程序或者小游戏的名称.
@property (nonatomic, readonly) NSString *name;
///小程序或者小游戏的图标URL.
@property (nonatomic, readonly) NSString *iconURL;

#pragma mark - Debug Info

///测试版元信息.(BDPSchemaVersionV02废弃)
@property (nonatomic, readonly, nullable) NSString *url;
///测试版元信息,格式为Dictionary.(BDPSchemaVersionV02废弃)
@property (nonatomic, readonly, nullable) NSDictionary *urlDictionary;

//#pragma mark - Common Params For Event Track

/////用于埋点,小程序或者小游戏的ttid.
@property (nonatomic, readonly) NSString *ttid;
///用于宿主方来源埋点,入口来源.
@property (nonatomic, readonly) NSString *launchFrom;
///用于宿主方来源埋点,配合launchFrom字段确定来源位置.(有些宿主需要两个字段才能定位一个位置)
@property (nonatomic, readonly) NSString *location;
/////用于业务方来源埋点.(与宿主无关)
@property (nonatomic, readonly) NSString *bizLocation;
///用于宿主方来源埋点,记录小程序/小游戏最起始入口。即连续跳转之后，最开始的入口信息
@property (nonatomic, readonly) NSString *originEntrance;

#pragma mark - Scene

///入口场景,有效范围(0,+∞).
@property (nonatomic, readonly, nullable) NSString *scene;
///入口子场景,有效范围(0,+∞).
@property (nonatomic, readonly, nullable) NSString *subScene;

#pragma mark - Start Page

///启动页面,仅小程序使用,为 {startPagePath}?{startPageQuery} 格式.
@property (nonatomic, readonly, nullable) NSString *startPage;
///启动页面Path参数,仅小程序使用.
@property (nonatomic, readonly, nullable) NSString *startPagePath;
///启动页面Query参数,格式为JSON字符串,仅小程序使用.
@property (nonatomic, readonly, nullable) NSString *startPageQuery;
///启动页面Query参数,格式为Dictionary,仅小程序使用.
@property (nonatomic, readonly, nullable) NSDictionary *startPageQueryDictionary;

#pragma mark - Query

///启动参数,格式为JSON字符串,仅小游戏使用.
@property (nonatomic, readonly, nullable) NSString *query;
///启动参数,格式为Dictionary,仅小游戏使用.
@property (nonatomic, readonly, nullable) NSDictionary *queryDictionary;

#pragma mark - Extra

///扩展字段,格式为JSON字符串.(使用 string/array/dictionaryValueFromExtraForKey: 方法获取具体内容)
@property (nonatomic, readonly, nullable) NSString *extra;
///扩展字段,格式为Dictionary.(仅内部使用)
@property (nonatomic, readonly) NSDictionary *extraDictionary;

#pragma mark - BDP Log

///埋点参数信息字段,格式为JSON字符串.
@property (nonatomic, readonly) NSString *bdpLog;
///埋点参数信息字段,格式为Dictionary.(仅内部使用)
@property (nonatomic, readonly) NSDictionary *bdpLogDictionary;

#pragma mark - Business Params

///业务数据: 小程序转跳参数,格式为Dictionary.（跳转后台时会清除）
@property (nonatomic, readonly, nullable) NSDictionary *refererInfoDictionary;

///业务数据: 群共享参数.
@property (nonatomic, readonly, nullable) NSString *shareTicket;

/// vdom 的链接，一般情况下是不会有这个参数的，为了调试方便
/// 暂时屏蔽该功能，代码保留。
@property (nonatomic, readonly, nullable) NSString *snapshotUrl;

#pragma mark - 埋点信息字典,仅用于SDK内部埋点使用
@property (nonatomic, strong) NSDictionary *schemaCodecTrackInfo;

#pragma mark - Debug
/// Lark 真机调试 web scoket 地址
@property (nonatomic, copy, nullable) NSString *wsForDebug;
/// IDE web-view安全域名调试开关
@property (nonatomic, readonly) NSString *ideDisableDomainCheck;

#pragma mark - XScreen 半屏
/// panel为半屏
@property (nonatomic, copy) NSString *mode;

/// 样式：high medium low，屏幕比例不一致
@property (nonatomic, copy) NSString *XScreenPresentationStyle;

@property (nonatomic, copy) NSString *presentationStyle;

@property (nonatomic, copy) NSString *chatID;

#pragma mark - Life Cycle

- (instancetype)init NS_UNAVAILABLE;

#pragma mark - Interface

/**
 @brief 更新startPage属性
 @param startPage startPage字符串
 */
- (void)updateStartPage:(NSString *)startPage;

#pragma mark - Interface: Business Params

/**
 @brief 更新scene属性(仅供小程序跳小程序使用)
 @param scene scene字符串
 */
- (void)updateScene:(NSString *)scene;

/**
 @brief 更新launchFrom属性(仅供小程序跳小程序使用)
 @param launchFrom launchFrom字符串
 */
- (void)updateLaunchFrom:(NSString *)launchFrom;

/**
 @brief 更新refererInfoDictionary属性(仅供小程序跳小程序使用)
 @param refererInfoDictionary refererInfoDictionary字典
 */
- (void)updateRefererInfoDictionary:(NSDictionary *)refererInfoDictionary;

#pragma mark - Extra

/**
 @brief 获取extraDictionary中字段的值(找extraDictionary)
 @param key 字段的key
 @return 字段的value
 */
- (NSString *)stringValueFromExtraForKey:(NSString *)key;

/**
 @brief 获取extraDictionary中字段的值(找extraDictionary)
 @param key 字段的key
 @return 字段的value
 */
- (NSArray *)arrayValueFromExtraForKey:(NSString *)key;

/**
 @brief 获取extraDictionary中字段的值(找extraDictionary)
 @param key 字段的key
 @return 字段的value
 */
- (NSDictionary *)dictionaryValueFromExtraForKey:(NSString *)key;

#pragma mark - GroupId

/**
 @brief 获取group_id，头条在extra中的evnet_extra，抖音在bdp_log
 @return group_id
 */
- (NSString *)groupId;

#pragma mark - launchType

/**
 @brief 获取小程序的launchType，默认normal，重启时为restart，暂时只有这两种
 @return 字段的value
 */
- (NSString *)launchType;

#pragma mark - GD ext

/**
 @brief 获取gd_ext_json
 */
///主端Schema通用参数字段,格式为JSON字符串.
@property (nonatomic, readonly, nullable) NSString *gdExt;
///主端Schema通用参数字段,格式为Dictionary
@property (nonatomic, readonly, nullable) NSDictionary *gdExtDictionary;

@end
