//
//  BDPSchemaCodec+Private.h
//  Timor
//
//  Created by liubo on 2019/4/11.
//

#import "BDPSchemaCodec.h"

#pragma mark - BDPSchemaCodecOptions Private

///以下方法仅供SDK内部使用!
@interface BDPSchemaCodecOptions ()

///兼容逻辑: "分享"和"小程序转跳", 前端会返回拼接完整的"start_page"和"query", 对于这种直接拼接到schema.(仅供SDK内部使用)
/// 需要注意⚠️：这个内容需要是已经 encode 后的内容，是直接通过字符串拼接的方式被拼接到 schema 中
@property (nonatomic, copy) NSString *fullStartPage;

/// 已经 decode 后的 startPage(包含参数) 内容 (仅供SDK内部读取使用)
@property (nonatomic, copy) NSString *fullStartPageDecoded;

///兼容逻辑: "分享"和"小程序转跳", 前端会返回拼接完整的"start_page"和"query", 对于这种直接拼接到schema.(仅供SDK内部使用)
@property (nonatomic, copy) NSString *fullquery;

/**
 @brief 判断两个BDPSchemaCodecOptions实例是否相等
 @param object 另一个BDPSchemaCodecOptions实例
 @return 两个BDPSchemaCodecOptions实例是否相等
 */
- (BOOL)isEqualToOption:(BDPSchemaCodecOptions *)object;

@end

#pragma mark - BDPSchema Private

///以下方法仅供SDK内部使用!
@interface BDPSchemaCodec ()

#pragma mark - Protect Interface

/**
 @brief 将schema的URL解析成 BDPSchema 实例
 @param url 要解析的schema的URL
 @param appType 这里为了支持H5小程序的老代码，后续考虑删除
 @param error 解析错误信息,参考 BDPSchemaCodecError
 @return 解析成的 BDPSchema 实例
 */
+ (BDPSchema * _Nullable)schemaFromURL:(NSURL *)url appType:(OPAppType)appType error:(NSError **)error;

#pragma mark - Private Interface

/**
 @brief 拆分schema中的protocol & host & query
 @param urlString schema字符串
 @param resultBlock 拆分结果
 */
+ (void)separateProtocolHostAndParams:(NSString *)urlString syncResultBlock:(void (^)(NSString *protocol, NSString *host, NSString *fullHost, NSDictionary *params))resultBlock;

/**
 @brief 拆分startPage中的path和query
 @param urlString startPage字符串
 @param resultBlock 拆分结果
 */
+ (void)separatePathAndQuery:(NSString *)urlString syncResultBlock:(void (^)(NSString *path, NSString *query, NSDictionary *queryDictionary))resultBlock;

#pragma mark - Private BDPSchema Helper

+ (void)constructStartPageForSchema:(BDPSchema *)schema;

#pragma mark - Private Encode Helper

+ (NSString *)urlEncodeJSONRepresentationForObj:(id)object;

@end
