//
//  BDXElementResourceManager.h
//  BDXElement
//
//  Created by li keliang on 2020/3/17.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDXElementLocalizedStringKey) {
    BDXElementLocalizedStringKeyConfirm = 1,
    BDXElementLocalizedStringKeyCancel,
    BDXElementLocalizedStringKeyNetworkError,
    BDXElementLocalizedStringKeyErrorOccurred,
    BDXElementLocalizedStringKeyYear,
    BDXElementLocalizedStringKeyMonth,
};

static NSString * const BDXElementContextContainerKey = @"BDXElementContextContainerKey";
static NSString * const BDXElementContextShouldFallbackBlockKey = @"BDXElementContextShouldFallbackBlockKey";

typedef BOOL(^BDXElementShouldFallbackBlock)(NSError *error);

/// Description Used to localize plural strings
/// @param key The key of type BDXElementLocalizedStringKey
/// @param default The default format localized string used to form a filled localized string
/// @param count The count of numbers used to fill the placeholders in the format string
/// @param ... The numbers used to fill the placeholders in the format string
#define BDXElementPluralLocalizedString(key, default, count, ...) ({ \
    NSString *string = nil; \
    if (BDXElementResourceManager.sharedInstance.localizeStringBlock) { \
        string = BDXElementResourceManager.sharedInstance.localizeStringBlock((key), (default), (count), ##__VA_ARGS__); \
    } \
    if (!string) { \
        string = [NSString stringWithFormat:(default), ##__VA_ARGS__]; \
    } \
    string; \
})

#define BDXElementLocalizedString(key, default) BDXElementPluralLocalizedString(key, default, 0)

typedef void(^BDXElementResourceCompletionHandler)(NSData * _Nullable data, NSError * _Nullable error);
typedef void(^BDXElementLocalFileCompletionHandler)(NSURL * _Nullable url, NSError * _Nullable error);

@protocol BDXElementResourceManagerDelegate <NSObject>

- (void)fetchResourceDataWithURLString:(NSString *)urlString context:(nullable NSDictionary *)context  completionHandler:(BDXElementResourceCompletionHandler)completionHandler;
- (void)fetchLocalFileWithURLString:(NSString *)urlString context:(nullable NSDictionary *)context  completionHandler:(BDXElementLocalFileCompletionHandler)completionHandler;

@end

@interface BDXElementResourceManager : NSObject

@property (nonatomic, weak) id<BDXElementResourceManagerDelegate> resourceDelegate;
@property (nonatomic, copy) NSString * _Nullable (^localizeStringBlock)(BDXElementLocalizedStringKey key, NSString *defaultString, NSUInteger argc, ...);

+ (instancetype)sharedInstance;

- (void)resourceDataWithURL:(NSURL *)URL baseURL:(nullable NSURL *)baseURL context:(nullable NSDictionary*)context  completionHandler:(void (^)(NSURL *url, NSData * _Nullable data, NSError * _Nullable error))completionHandler;

- (void)fetchLocalFileWithURL:(NSURL *)aURL baseURL:(nullable NSURL *)aBaseURL context:(NSDictionary*)context completionHandler:(void (^)(NSURL *localUrl, NSURL *remoteUrl, NSError * _Nullable error))completionHandler;

- (void)downloadZipFileWithURL:(NSURL *)URL completionHandler:(void (^)(NSURL *URL, NSURL *unzipURL, NSError * _Nullable error))completionHandler;

- (void)resourceZipFileWithURL:(NSURL *)aURL baseURL:(nullable NSURL *)aBaseURL context:(NSDictionary*)context completionHandler:(void (^)(NSURL *URL, NSURL *unzipURL, NSError * _Nullable error))completionHandler;

- (void)fetchFileWithURL:(NSURL *)URL baseURL:(nullable NSURL *)aBaseURL context:(NSDictionary*)context completionHandler:(void (^)(NSURL *localUrl, NSURL *remoteUrl, NSError * _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
