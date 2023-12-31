//
//  TTNetworkUtil.h
//  Pods
//
//  Created by ZhangLeonardo on 15/9/6.
//
//  Network library tools class

#import <Foundation/Foundation.h>
#import "TTNetworkManager.h"


extern NSString * const Key;
extern int g_request_timeout;
extern int g_request_count_network_changed;
extern double g_concurrent_request_connect_interval;
extern double g_concurrent_request_delta_timeout;

extern NSString * base64EncodedString(NSData *data);

/**
 *  Judging whether it is an empty string,
 *  the reason for the disgusting name is because
 *  the network library does not want to rely on other libraries,
 *  and the method exists in the basic library.
 *
 *  @param str   String to be judged
 *
 *  @return YES   Is an empty string
 */
#ifndef isEmptyStringForNetworkUtil
#define isEmptyStringForNetworkUtil(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#endif

#define ENABLE_PARAMS_ENCRYPTION

#define YY_FOUR_CC(c1,c2,c3,c4) ((uint32_t)(((c4) << 24) | ((c3) << 16) | ((c2) << 8) | (c1)))
#define YY_TWO_CC(c1,c2) ((uint16_t)(((c2) << 8) | (c1)))

typedef NS_ENUM(NSUInteger, ImageType) {
    ImageTypeUnknown = 0, ///< unknown
    ImageTypeJPEG,        ///< jpeg, jpg
    ImageTypeJPEG2000,    ///< jp2
    ImageTypeTIFF,        ///< tiff, tif
    ImageTypeBMP,         ///< bmp
    ImageTypeICO,         ///< ico
    ImageTypeICNS,        ///< icns
    ImageTypeGIF,         ///< gif
    ImageTypePNG,         ///< png
    ImageTypeWebP,        ///< webp
    ImageTypeHeic,        ///< Heic, imageIO support （ftypheic ....ftypheix ....ftyphevc ....ftyphevx）
    ImageTypeHeif,        ///< Heif, currently(20180311) no imageIO support （mif1，msf1）
};

/**
 * Delay execute Block Handler
 */
typedef void(^TTDelayedBlockHandle)(BOOL cancel);

@interface QueryPairObject : NSObject

@property (nonatomic, copy) NSString *key;

@property (nonatomic, copy) NSString *value;

- (instancetype)initWithKey:(NSString *)key value:(NSString *)value;

@end




//detail subtask info in concurrent request
//put it here so that slardar can resolve the detail info by including this file
@interface TaskDetailInfo : NSObject
@property (nonatomic, copy) NSString *host;
@property (nonatomic, assign) NSTimeInterval start;
@property (nonatomic, assign) NSTimeInterval end;
@property (nonatomic, assign) NSInteger netError;
@property (nonatomic, assign) NSInteger httpCode;

@property (nonatomic, copy) NSString* dispatchedHost;
@property (nonatomic, assign) NSTimeInterval dispatchTime;
@property (nonatomic, assign) BOOL sentAlready;
@end




@interface TTNetworkUtil : NSObject


/**
 *  Construct URL through Str.
 *  If it fails, try to remove the invisible characters before and after the URL.
 *  If it still fails, try UTF8 encoding.
 *
 *  @param str String of URL
 *
 *  @return URL object after construction
 */
+ (NSURL *)URLWithURLString:(NSString *)str;

/**
 *  Construct URL through Str, the construction method is the same as URLWithURLString, first try without baseURL.
 *  If it fails, try to add baseURL.
 *
 *  @param str    String of URL
 *  @param baseURL base URL, can be empty
 *
 *  @return URL object after construction
 */
+ (NSURL *)URLWithURLString:(NSString *)str baseURL:(NSURL *)baseURL;

/**
 *  Add general parameters to a URL string
 *
 *  @param URLStr       URL string to be spliced
 *  @param commonParams  Common parameters to be spliced
 *
 *  @return URL string after splicing
 */
+ (NSString*)URLString:(NSString *)URLStr appendCommonParams:(NSDictionary *)commonParams;

/*!
 *  @brief Add general parameters to a URL string, which may contain fragment.
 *
 *  @param URLStr       URL string to be spliced
 *  @param commonParams  Common parameters to be spliced
 *
 *  @return URL string after splicing
 */
+ (NSString *)webviewURLString:(NSString *)URLStr appendCommonParams:(NSDictionary *)commonParams;

+ (NSString *)filterSensitiveParams:(NSString *)inputUrl outputUrl:(NSString **)outputUrl onlyInHeader:(BOOL)onlyInHeader keepPlainQuery:(BOOL)keepPlainQuery;

+ (NSString *)md5Hex:(NSData *)data;

/**
 * Delay execute Block
 */
+ (TTDelayedBlockHandle)dispatchBlockAfterDelay:(int64_t)delta
                                          block:(dispatch_block_t)block;
/**
 * Immediate execute delay Block
 */
+ (void)dispatchDelayedBlockImmediately:(TTDelayedBlockHandle)delayedHandle;

+ (NSString *)calculateFileMd5WithFilePath:(NSString *)filePath;

+ (NSString *)getNONEmptyString:(NSString*)str;

/**
 * NSURL.path won`t return the last '/' in  path, here we handle this problem
 */
+ (NSString *)getRealPath:(NSURL *)URL;

+ (BOOL)isMatching:(NSString *)target pattern:(TTNetworkManagerPathMatchingType)pattern source:(NSArray<NSString *> *)source;

+ (BOOL)isPathMatching:(NSString *)path pathFilterDictionary:(NSDictionary<TTNetworkManagerPathMatchingType, NSArray<NSString *> *> *)pathFilterDictionary;

+ (NSURL *)isValidURL:(NSString *)url callback:(TTNetworkJSONFinishBlock)callback callbackWithResponse:(TTNetworkJSONFinishBlockWithResponse)callbackWithResponse;

+ (void)parseCommonParamsConfig:(NSDictionary *)data;

+ (NSArray *)mergeOneNSArray:(NSArray *)arr1 withAnother:(NSArray *)arr2;

+ (NSDictionary *)getMinExcludingCommonParams:(NSDictionary *)appLogCommonParams;

+ (NSString *)loadTTNetOCVersionFromPlist;

+ (NSString *)addComponentVersionToRequestLog:(NSString *)originalRequestLog;

+ (NSString *)addCompressLogToRequestLog:(NSString *)originalRequestLog compressLog:(NSString *)compressLog;

+ (NSDictionary *)convertQueryToDict:(NSString *)queryString;

+ (ImageType)imageTypeDetect:(CFDataRef)data;

+ (NSString *)imageTypeString:(ImageType)type;

+ (NSString *)replaceFirstAppearString:(NSString *)originalString target:(NSString *)targetString toString:(NSString *)newString;

+ (BOOL)doesQueryContainKey:(NSString *)originalQueryString keyName:(NSString *)keyName keyValue:(NSString *)keyValue;

@end
