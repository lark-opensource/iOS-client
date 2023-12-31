//
//  BDPSchemaCodec.h
//  Timor
//
//  Created by liubo on 2019/4/11.
//

#import "BDPSchema.h"

#pragma mark - BDPSchemaCodecError

extern NSString * const BDPSchemaCodecErrorDomain;

///SchemaCodec错误码
typedef NS_ENUM(NSInteger, BDPSchemaCodecError) {
    //serialize
    BDPSchemaCodecErrorInvalidOption = 1,   //!< 无效的Options
    BDPSchemaCodecErrorHost,                //!< 无效的Host
    BDPSchemaCodecErrorAppID,               //!< 无效的AppID
    BDPSchemaCodecErrorVersionType,         //!< 无效的VersionType
    BDPSchemaCodecErrorPath,                //!< 无效的Path
    BDPSchemaCodecErrorCheck,               //!< 无效的Check
    BDPSchemaCodecErrorLaunchMode,          //!< 无效的LaunchMode
    
    //deserialize
    BDPSchemaCodecErrorInvalidURL = 101,    //!< 无效的URL
    BDPSchemaCodecErrorEmptyCheck,          //!< 校验字段为空
    BDPSchemaCodecErrorIllegalCheck,        //!< 错误的校验字段
};

#pragma mark - BDPSchemaBDPLogKey

///BDPLog中的这四个字段,将作为埋点的通用参数,被加入到所有埋点信息中.
extern NSString * const BDPSchemaBDPLogKeyLaunchFrom;   //!< @"launch_from"
extern NSString * const BDPSchemaBDPLogKeyTtid;         //!< @"ttid"
extern NSString * const BDPSchemaBDPLogKeyLocation;     //!< @"location"
extern NSString * const BDPSchemaBDPLogKeyBizLocation;  //!< @"biz_location"
extern NSString * const BDPSchemaBDPLogKeyOriginEntrance;   //!< @"origin_entrance"
extern NSString * const kBDPSchemaKeyWSForDebug;  // 真机调试 web socket 地址

#pragma mark - BDPSchemaCodecOptions

@interface BDPSchemaCodecOptions : NSObject

@property (nonatomic, copy, nullable) NSString *leastVersion;
///SchemaCodecOptions 报错信息
@property (nonatomic, copy, nullable) NSError *error;

///支持的版本号,默认@"v2"(不支持修改).
@property (nonatomic, readonly, nullable) NSString *schemaVersion;

///宿主schema,默认@"sslocal".(必填)(如: 本地测试@"sslocal", 头条正式版@"snssdk141", 头条测试版@"snssdk147", 抖音@"snssdk1128"等)
@property (nonatomic, copy, nullable) NSString *protocol;

///host类型,默认SCHEMA_APP.(必填)(注意: 需要为二者之一:小程序SCHEMA_APP
@property (nonatomic, copy, nullable) NSString *host;

///小程序或者小游戏的ID.(必填)
@property (nonatomic, copy, nullable) NSString *appID;

/// identifier (选填)
@property (nonatomic, copy, nullable) NSString *identifier;

/// instanceID (选填)
@property (nonatomic, copy, nullable) NSString *instanceID;

///版本类别,仅支持BDPSchemaVersionType指定的类型,默认BDPSchemaVersionTypeCurrent.(必填)
@property (nonatomic, assign) OPAppVersionType versionType;

///获取版本需要的token.(BDPSchemaVersionTypePreview和BDPSchemaVersionTypeLocalDev版本时必填).
@property (nonatomic, copy, nullable) NSString *token;

///小程序或者小游戏的meta,仅支持@"name",@"icon"两个字段.(value支持: NSString | NSNumber | NSArray | NSDictionary)(选填,默认空字典)
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, id> *meta;

///入口场景.(选填)
@property (nonatomic, copy, nullable) NSString *scene;

///埋点参数信息字段,通用参数字段参考BDPSchemaBDPLogKey.(value支持: NSString | NSNumber | NSArray | NSDictionary)(选填,默认空字典)
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, id> *bdpLog;

///启动页面Path参数,仅小程序使用.(选填)
@property (nonatomic, copy, nullable) NSString *path;

///启动参数.(value支持: NSString | NSNumber | NSArray | NSDictionary)(选填,默认空字典)
@property (nonatomic, strong, nonnull) NSMutableDictionary<NSString *, id> *query;

///Android专用:启动模式,仅支持@"hostStack".(选填)
@property (nonatomic, copy, nullable) NSString *launchMode;

///Android专用:真机远程调试参数.(value支持: NSString | NSNumber | NSArray | NSDictionary)(选填,默认空字典)
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, id> *inspect;

/// Lark 真机调试 web scoket 地址
@property (nonatomic, copy, nullable) NSString *wsForDebug;

/// IDE web-view安全域名调试开关
@property (nonatomic, copy, nullable) NSString *ideDisableDomainCheck;

/// 标识是否强制冷启动
@property (nonatomic, assign) BOOL relaunchWhileLaunching;

@property (nonatomic, copy, nullable) NSString *XScreenMode;
@property (nonatomic, copy, nullable) NSString *XScreenPresentationStyle;
@property (nonatomic, copy, nullable) NSString *chatID;

/**
 @brief 自定义字段,包含的内容会被拼接到schema字符串顶级.(value支持: NSString | NSNumber | NSArray | NSDictionary)(选填,默认空字典)
 @note 注意:以下列举的为schema内部保留key,customFields中相同的key将被忽略,不会被拼接到schema中.
 @note @"version", @"bdpsum", @"app_id", @"version_type", @"token", @"meta", @"start_page", @"query", @"scene", @"bdp_log", @"refererInfo", @"launch_mode", @"inspect"
 */

//2.37新增判定启动类型参数，默认normal，重启时为restart，暂时只有这两种
#define BDPLaunchTypeKey @"bdp_launch_type"
#define BDPLaunchTypeRestart @"restart"
#define BDPLaunchTypeNormal @"normal"

/// 小程序启动自定义参数，目前只有Lark用
#define kBDPSchemaKeyCustomFieldBDPLaunchQuery @"bdp_launch_query"
#define kBDPSchemaKeyCustomFieldRequestAbility @"required_launch_ability"
#define kBDPSchemaKeyAbilityMessageAction @"message_action"
#define kBDPSchemaKeyAbilityChatAction @"chat_action"
#define kBDPSchemaKeyLeastVersion @"leastVersion"
#define kBDPSchemaKeyRelaunchWhileLaunching @"relaunch"
#define kBDPSchemaKeyRelaunchWhileLaunchingPath @"path"

@property (nonatomic, strong, nonnull) NSMutableDictionary<NSString *, id> *customFields;



#pragma mark - Private

///业务数据: 小程序转跳参数.(仅供SDK内部使用)
@property (nonatomic, strong, nonnull) NSMutableDictionary<NSString *, id> *refererInfoDictionary;

@end

#pragma mark - BDPSchemaCodec

@interface BDPSchemaCodec : NSObject

#pragma mark - Public Interface

/**
 @brief 将schema的URL解析成 BDPSchemaCodecOptions 实例
 @param url 要解析的schema的URL
 @param error 解析错误信息,参考 BDPSchemaCodecError
 @return 解析成的 BDPSchemaCodecOptions 实例
 */
+ (BDPSchemaCodecOptions *)schemaCodecOptionsFromURL:(NSURL *)url error:(NSError **)error;

/**
 @brief 将 BDPSchemaCodecOptions 实例序列化成schema字符串
 @param options 要序列化的 BDPSchemaCodecOptions 实例
 @param error 序列化错误信息,参考 BDPSchemaCodecError
 @return 序列化的schema字符串
 */
+ (NSString *)schemaStringFromCodecOptions:(BDPSchemaCodecOptions *)options error:(NSError **)error;

/**
 @brief 将 BDPSchemaCodecOptions 实例序列化成schema的URL
 @param options 要序列化的 BDPSchemaCodecOptions 实例
 @param error 序列化错误信息,参考 BDPSchemaCodecError
 @return 序列化的schema的URL
 */
+ (NSURL *)schemaURLFromCodecOptions:(BDPSchemaCodecOptions *)options error:(NSError **)error;

@end
