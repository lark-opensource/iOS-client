//
//  TTVideoEngineSettings.h
//  TTVideoEngine
//
//  Created by 黄清 on 2021/5/26.
//

#import <Foundation/Foundation.h>
#include <VCVodSettings/VodSettingsManager.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TTVideoEngineServiceVendorType) {
    TTVideoEngineServiceVendorCN   = 0x010,
    TTVideoEngineServiceVendorSG,
    TTVideoEngineServiceVendorVA,
};


@protocol TTVideoEngineNetClient;
@interface TTVideoEngineSettings : NSObject
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (instancetype)settings;

/// Whether to enable.
@property (nonatomic, assign) BOOL enable;
- (TTVideoEngineSettings *(^)(BOOL debug))setDebug;

/// Need to use ttnet.
@property (nonatomic, strong) id<TTVideoEngineNetClient> netClient;
- (TTVideoEngineSettings *(^)(id<TTVideoEngineNetClient> netClinet))setNetClient;

/// host info.
@property (nonatomic, copy) NSString *usEast;
- (TTVideoEngineSettings *(^)(NSString *hostString))setUSEast;
@property (nonatomic, copy) NSString *sgSingapore;
- (TTVideoEngineSettings *(^)(NSString *hostString))setSGSingapore;
@property (nonatomic, copy) NSString *cnNorth;
- (TTVideoEngineSettings *(^)(NSString *hostString))setCNNorth;

@end




/// Engine use.
@interface TTVideoEngineSettings ()

@property (nonatomic, assign) BOOL debug;
- (TTVideoEngineSettings *(^)(BOOL enable))setEnable;

- (TTVideoEngineSettings *(^)(void))config;

- (TTVideoEngineSettings *(^)(void))load;

+ (VodSettingsManager *)manager;

@end

@interface TTVideoEngineSettings (Get)

- (nullable NSNumber *)getVodNumber:(NSString *)key dValue:(nullable NSNumber *)dValue;
- (nullable NSString *)getVodString:(NSString *)key dValue:(nullable NSString *)dValue;
- (nullable NSDictionary *)getVodDict:(NSString *)key;
- (nullable NSArray *)getVodArray:(NSString *)key dValue:(nullable NSArray *)dValue;

- (nullable NSNumber *)getMDLNumber:(NSString *)key dValue:(nullable NSNumber *)dValue;
- (nullable NSString *)getMDLString:(NSString *)key dValue:(nullable NSString *)dValue;
- (nullable NSDictionary *)getMDLDict:(NSString *)key;
- (nullable NSArray *)getMDLArray:(NSString *)key dValue:(nullable NSArray *)dValue;

- (nullable NSDictionary *)getJson:(NSInteger) module;

@end

NS_ASSUME_NONNULL_END
