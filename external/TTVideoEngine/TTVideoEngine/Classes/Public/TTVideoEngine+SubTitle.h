//
//  TTVideoEngine+SubTitle.h
//  TTVideoEngine
//
//  Created by haocheng on 2020/11/4.
//

#import "TTVideoEngine.h"

NS_ASSUME_NONNULL_BEGIN

//sub model json field name
static NSString *const kTTVideoEngineSubModelURLKey = @"url";
static NSString *const kTTVideoEngineSubModelLangIdKey = @"language_id";
static NSString *const kTTVideoEngineSubModelFormatKey = @"format";
static NSString *const kTTVideoEngineSubModelSubtitleIdKey = @"sub_id";
static NSString *const kTTVideoEngineSubModelIndexKey = @"id";
static NSString *const kTTVideoEngineSubModelLanguageKey = @"language";
static NSString *const kTTVideoEngineSubModelExpireTimeKey = @"expire";
static NSString *const kTTVideoEngineSubModelListKey = @"list";

@protocol TTVideoEngineSubDecInfoProtocol <NSObject>

- (NSString *_Nullable)jsonString;
- (NSInteger)subtitleCount;

@end

@protocol TTVideoEngineSubProtocol <NSObject>

//required
/* json field name: "language_id" */
@property (nonatomic, assign, readonly) NSInteger languageId;
/* json field name: "url" */
@property (nonatomic, copy, readonly) NSString *urlString;
/* json field name: "format" */
@property (nonatomic, copy, readonly) NSString *format;
/* json field name: "sub_id" */
@property (nonatomic, assign, readonly) NSInteger subtitleId;

- (NSDictionary *_Nullable)toDictionary;
- (NSString *_Nullable)jsonString;

@end

@interface TTVideoEngineSubModel : NSObject <TTVideoEngineSubProtocol>

//optional
@property (nonatomic, assign, readonly) NSInteger index;
@property (nonatomic, copy, readonly) NSString *language;
@property (nonatomic, assign, readonly) NSInteger expireTime;

- (instancetype)initWithDictionary:(NSDictionary * _Nonnull)dict;
- (NSDictionary *_Nullable)toDictionary;
- (NSString *_Nullable)jsonString;

@end

@interface TTVideoEngineSubDecInfoModel : NSObject <TTVideoEngineSubDecInfoProtocol>

- (instancetype)initWithDictionary:(NSDictionary *_Nonnull)dict;
- (instancetype)initWithSubModels:(NSArray<id<TTVideoEngineSubProtocol>> *_Nonnull)models;

- (void)addSubModel:(id<TTVideoEngineSubProtocol> _Nonnull)model;

- (NSString *_Nullable)jsonString;
- (NSInteger)subtitleCount;

@end

@interface TTVideoEngineSubInfo: NSObject

@property (nonatomic, assign) NSInteger pts;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, assign) NSInteger duration;

@end

@interface TTVideoEngineLoadInfo: NSObject

@property (nonatomic, assign) NSInteger firstPts;
@property (nonatomic, assign) NSInteger code;

@end

@protocol TTVideoEngineSubtitleDelegate <NSObject>

@optional

- (void)videoEngine:(TTVideoEngine *)videoEngine onSubtitleInfoCallBack:(NSString *)content pts:(NSUInteger)pts;

- (void)videoEngine:(TTVideoEngine *)videoEngine onSubtitleInfoCallBack:(TTVideoEngineSubInfo *)subInfo;

- (void)videoEngine:(TTVideoEngine *)videoEngine onSubtitleInfoRequested:(id _Nullable)info error:(NSError * _Nullable)error;

- (void)videoEngine:(TTVideoEngine *)videoEngine onSubSwitchCompleted:(BOOL)success currentSubtitleId:(NSInteger)currentSubtitleId;

/** DEPRECATED_MSG_ATTRIBUTE, use function below instead */
- (void)videoEngine:(TTVideoEngine *)videoEngine onSubLoadFinished:(BOOL)success;

- (void)videoEngine:(TTVideoEngine *)videoEngine onSubLoadFinished:(BOOL)success info:(TTVideoEngineLoadInfo * _Nullable)info;

@end

@interface TTVideoEngine()
/* host name of subtitle request */
@property (nonatomic, copy) NSString *subtitleHostName;
/* subtitle delegate */
@property (nonatomic, weak, nullable) id<TTVideoEngineSubtitleDelegate> subtitleDelegate;
/* subtitle model */
@property (nonatomic, strong) id<TTVideoEngineSubDecInfoProtocol> subDecInfoModel;

@end

@interface TTVideoEngine(SubTitle)

/* subtitle requested info*/
- (NSDictionary * _Nullable)requestedSubtitleInfo;

/* subtitle language infos from video model*/
- (NSArray * _Nullable)subtitleInfos;

/* is video has embedded subtitle (in video frame)
 * get from video model info
 */
- (BOOL)hasEmbeddedSubtitle;

- (void)switchNewSubtitleModel:(id<TTVideoEngineSubProtocol>)subModel;

/** pre_request method */
+ (void)requestSubtitleInfoWith:(NSString * _Nonnull)hostName
                            vid:(NSString * _Nonnull)vid
                         fileId:(NSString * _Nonnull)fileId
                       language:(NSString * _Nullable)language
                         client:(id<TTVideoEngineNetClient> _Nullable)client
                     completion:(nullable void (^)(id _Nullable jsonObject, NSError * _Nullable error))completionHandler;

- (TTVideoEngineSubInfo *)getSubtitleInfo:(NSInteger)queryTime;

@end

NS_ASSUME_NONNULL_END
