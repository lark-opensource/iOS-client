//
//  ECOCookieService.h
//  ECOInfra
//
//  Created by Meng on 2021/2/18.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "ECOCookieStorage.h"

NS_ASSUME_NONNULL_BEGIN

@protocol GadgetCookieIdentifier <NSObject>

@property (nonatomic, readonly) NSString *appID;
@property (nonatomic, readonly) NSString *fullString;

@end

/// ECOCookieService
/// 全局 Cookie 策略，可根据 identifier 隔离存储
@protocol ECOCookieService <NSObject>

/// 根据 identifer 获取隔离后的 CookieStorage
///
/// @param identifier identifier 隔离的 key，如果为 nil 则返回全局 CookieStorage
- (nullable id<ECOCookieStorage>)cookieStorageWithIdentifier: (nullable NSString *)identifier;

/// gadget 隔离级别的 CookieStorage
/// 目前是根据 FG 与灰度策略来决定 Global/Gadget 的读写策略，全量后为仅 Gadget 隔离数据
/// 即全量后迁移到 `cookieStorage(withIdentifier:)` 接口
///
/// @param uniqueId uniqueId
- (nullable id<ECOCookieStorage>)gadgetCookieStorageWithGadgetId: (nullable id<GadgetCookieIdentifier>)gadgetId NS_SWIFT_NAME(gadgetCookieStorage(with:));

/// 同步 gadget 隔离级别的 cookie 到 WKWebsiteDataStore
///
/// @param uniqueId uniqueId
- (void)syncGadgetWebsiteDataStoreWithGadgetId: (id<GadgetCookieIdentifier>)gadgetId dataStore: (WKWebsiteDataStore *)dataStore NS_SWIFT_NAME(syncGadgetWebsiteDataStore(with:dataStore:));

/// 获取 Cookie 诊断信息
/// @param uniqueId 需要诊断的uniqueId
- (NSArray<NSDictionary<NSString *, NSString *> *> *)getDiagnoseInfoWithGadgetId: (id<GadgetCookieIdentifier>)gadgetId NS_SWIFT_NAME(getDiagnoseInfo(with:));

@end

NS_ASSUME_NONNULL_END
