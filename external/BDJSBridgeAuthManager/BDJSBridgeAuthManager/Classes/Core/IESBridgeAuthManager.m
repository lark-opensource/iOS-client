//
//  IESBridgeAuthManager.m
//  IESWebKit
//
//  Created by Lizhen Hu on 2019/8/12.
//

#import "IESBridgeAuthManager.h"
#import "IESBridgeAuthModel.h"
#import "TTNetworkManager+IESWKAddition.h"
#import <BDAssert/BDAssert.h>
#import <Godzippa/NSData+Godzippa.h>
#import <objc/runtime.h>
#import <Heimdallr/HMDUserExceptionTracker.h>

NSString * const IESPiperDefaultNamespace = @"host";

#pragma mark - IESWKPOSTRequestJSONSerializer

#ifndef IWK_IS_EMPTY_STRING
#define IWK_IS_EMPTY_STRING(param) ( !(param) ? YES : ([(param) isKindOfClass:[NSString class]] ? (param).length == 0 : NO) )
#endif

#ifndef IWK_IS_EMPTY_ARRAY
#define IWK_IS_EMPTY_ARRAY(array) (!array || ![array isKindOfClass:[NSArray class]] || array.count == 0)
#endif

static NSString * const IWKBridgeAuthInfosKey = @"IWKBridgeAuthInfosKey_1";

@interface IESBridgeAuthManager ()

@property (nonatomic, class, copy) IESBridgeAuthRequestParams *requestParams;

@property (nonatomic, copy) NSDictionary<NSString *, NSArray<IESBridgeAuthRule *> *> *authRules;

@property (nonatomic, strong) NSMutableSet<NSString *> *privateDomains;

@property (nonatomic, strong) NSLock *methodSetLock;
@property (nonatomic, strong) NSMutableSet<NSString *> *publicMethods;
@property (nonatomic, strong) NSMutableSet<NSString *> *protectedMethods;
@property (nonatomic, strong) NSMutableSet<NSString *> *privateMethods;
@property (nonatomic, strong) NSMutableSet<NSString *> *secureMethods;

@property (nonatomic, copy) IESBridgeAuthPackage *authPackage;

@property (nonatomic, assign, getter=hasFetchedAuthInfos) BOOL fetchedAuthInfos;
@property (nonatomic, assign, getter=isFetchingAuthInfos) BOOL fetchingAuthInfos;
@property (nonatomic, assign, getter=hasUsedAuthInfosBeforeConfiguring) BOOL usedAuthInfosBeforeConfiguring;

@end

@implementation IESBridgeAuthManager

static NSString *p_boeHostSuffix = nil;

#pragma mark - Lifecycle

+ (instancetype)sharedManager
{
    return [self sharedManagerWithNamesapce:IESPiperDefaultNamespace];
}

+ (instancetype)sharedManagerWithNamesapce:(NSString *_Nullable)namespace;
{
    if (IWK_IS_EMPTY_STRING(namespace)) {
        namespace = IESPiperDefaultNamespace;
    }
    
    static NSMutableDictionary *sharedManagers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManagers = [NSMutableDictionary new];
    });
    
    @synchronized (self) {
        IESBridgeAuthManager *manager = sharedManagers[namespace];
        if (!manager) {
            manager = [IESBridgeAuthManager new];
            sharedManagers[namespace] = manager;
        }
        return manager;
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _privateDomains = [NSMutableSet set];

        _methodSetLock = [NSLock new];
        _publicMethods = [NSMutableSet set];
        _protectedMethods = [NSMutableSet set];
        _privateMethods = [NSMutableSet set];
        _secureMethods = [NSMutableSet set];
        
        // Move the default private domains into the CN subspec.
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wundeclared-selector"
        if ([self.class respondsToSelector:@selector(defaultPrivateDomains)]) {
            [self addPrivateDomains:[self.class performSelector:@selector(defaultPrivateDomains)]];
        }
        #pragma clang diagnostic pop
    }
    return self;
}


#pragma mark - Class Methods

+ (void)configureWithAuthDomain:(NSString *)authDomain accessKey:(NSString *)accessKey commonParams:(IESBridgeAuthCommonParamsBlock)commonParams
{
    [self configureWithAuthDomain:authDomain accessKey:accessKey afterDelay:0 commonParams:commonParams];
}

+ (void)configureWithAuthDomain:(NSString *)authDomain accessKey:(NSString *)accessKey afterDelay:(NSTimeInterval)delay commonParams:(IESBridgeAuthCommonParamsBlock)commonParams
{
    [self configureWithAuthDomain:authDomain accessKey:accessKey afterDelay:delay commonParams:commonParams extraChannels:nil];
}

+ (void)configureWithAuthDomain:(NSString *)authDomain accessKey:(NSString *)accessKey afterDelay:(NSTimeInterval)delay commonParams:(IESBridgeAuthCommonParamsBlock)commonParams extraChannels:(NSArray<NSString *> *)extraChannels
{
    [self configureWithAuthDomain:authDomain accessKey:accessKey boeHostSuffix:nil afterDelay:delay commonParams:commonParams extraChannels:extraChannels];
}

+ (void)configureWithAuthDomain:(NSString *)authDomain accessKey:(NSString *)accessKey boeHostSuffix:(NSString *)boeHostSuffix afterDelay:(NSTimeInterval)delay commonParams:(IESBridgeAuthCommonParamsBlock)commonParams extraChannels:(NSArray<NSString *> *)extraChannels
{
    BDParameterAssert(!IWK_IS_EMPTY_STRING(authDomain));
    BDParameterAssert(!IWK_IS_EMPTY_STRING(accessKey));
    BDParameterAssert(!!commonParams);
    BDAssert(!IESBridgeAuthManager.sharedManager.hasUsedAuthInfosBeforeConfiguring, @"The configure method should be called as soon ass possible before using any auth infos.");
    
    self.requestParams = [[IESBridgeAuthRequestParams alloc] init];
    self.requestParams.authDomain = authDomain;
    self.requestParams.accessKey = accessKey;
    self.requestParams.commonParams = commonParams;
    self.requestParams.extraChannels = extraChannels;
    p_boeHostSuffix = boeHostSuffix;
    
    // Prefer cache over built-in.
    NSArray<IESBridgeAuthPackage *> *packages = nil;
    id cachedAuthInfos = [NSUserDefaults.standardUserDefaults objectForKey:IWKBridgeAuthInfosKey];
    if (cachedAuthInfos) {
        @try {
            id data = [NSKeyedUnarchiver unarchiveObjectWithData:cachedAuthInfos];
            if ([data isKindOfClass:NSArray.class]) {
                packages = data;
            }
        } @catch (NSException *exception) {
            [[HMDUserExceptionTracker sharedTracker] trackCurrentThreadLogExceptionType:@"BridgeAuthCachesError" skippedDepth:0 customParams:@{
                @"caches" : [cachedAuthInfos description] ?: @"" ,
                @"exception" : exception.description ?: @""
            } filters:nil callback:nil];
        }
    }
    if (packages.count == 0 && IESBridgeAuthManager.sharedManager.isBuiltinAuthInfosEnabled) {
        NSError *error = nil;
        NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"jsb_auth_infos" withExtension:@"json.gz"];
        NSData *compressedData = [NSData dataWithContentsOfURL:fileURL];
        NSData *uncompressedData = [compressedData dataByGZipDecompressingDataWithError:&error];
        if (uncompressedData && !error) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:uncompressedData options:kNilOptions error:&error];
            if (json && !error) {
                packages = [self parseAuthInfosWithJSON:json accessKey:accessKey];
            }
        }
    }
    if ([packages isKindOfClass:NSArray.class] && packages.count > 0) {
        [self p_updateAuthManagerWithPackages:packages];
    } else {
        delay = 0;  // Fetch auth infos immediately if there isn't any caches.
    }

    if (delay > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self p_fetchAllAuthInfosIfNeeded];
        });
    } else {
        [self p_fetchAllAuthInfosIfNeeded];
    }
    
    IESBridgeAuthManager.sharedManager.usedAuthInfosBeforeConfiguring = NO;
}

+ (void)addPrivateDomains:(NSArray<NSString *> *)privateDomains inNamespace:(NSString *)namespace
{
    if (IWK_IS_EMPTY_STRING(namespace)) {
        namespace = IESPiperDefaultNamespace;
    }
    [[IESBridgeAuthManager sharedManagerWithNamesapce:namespace] addPrivateDomains:privateDomains];
}

+ (void)p_updateAuthManagerWithPackages:(NSArray *)packages
{
    [packages enumerateObjectsUsingBlock:^(IESBridgeAuthPackage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isBridgeAuthInfo) {
            [IESBridgeAuthManager sharedManagerWithNamesapce:obj.namespace].authPackage = obj;
        }
    }];
}

+ (void)p_fetchAllAuthInfosIfNeeded
{
    if (IESBridgeAuthManager.sharedManager.hasFetchedAuthInfos || IESBridgeAuthManager.sharedManager.isFetchingAuthInfos) {
        return;
    }
    
    IESBridgeAuthManager.sharedManager.fetchingAuthInfos = YES;
    
    NSString *authDomain = self.requestParams.authDomain;
    NSString *accessKey = self.requestParams.accessKey;
    NSDictionary *commonParams = self.requestParams.commonParams ? self.requestParams.commonParams() : nil;
    NSArray<NSString *> *extraChannels = self.requestParams.extraChannels ? self.requestParams.extraChannels : nil;
    
    if (IWK_IS_EMPTY_STRING(authDomain) || IWK_IS_EMPTY_STRING(accessKey) || !commonParams) {
        return;
    }
    
    NSDictionary *requestParams = [self getRequestParamsWithAccessKey:accessKey commonParams:commonParams extraChannels:extraChannels];

    NSString *requestURL = [NSString stringWithFormat:@"https://%@/src/server/v2/package", authDomain];
    __weak typeof(self) weakSelf = self;
    static NSUInteger retryCount;
    [TTNetworkManager.shareInstance requestWithURL:requestURL method:@"POST" params:requestParams callback:^(NSError *error, id jsonObj) {
        IESBridgeAuthManager.sharedManager.fetchingAuthInfos = NO;
        
        __strong typeof(weakSelf) self = weakSelf;
        if (error) {
            if (retryCount<=2) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    retryCount++;
                    [self p_fetchAllAuthInfosIfNeeded];
                });
            }
        } else if ([jsonObj isKindOfClass:NSDictionary.class]) {
            NSArray<IESBridgeAuthPackage *> *packages = [self parseAuthInfosWithJSON:jsonObj accessKey:accessKey];
            if (packages.count > 0) {
                [self.class p_updateAuthManagerWithPackages:packages];
                
                // Cache the auth packages.
                id encodedData = [NSKeyedArchiver archivedDataWithRootObject:packages];
                [NSUserDefaults.standardUserDefaults setObject:encodedData forKey:IWKBridgeAuthInfosKey];
            }
            IESBridgeAuthManager.sharedManager.fetchedAuthInfos = YES;
        }
    }];
}

+ (NSArray<IESBridgeAuthPackage *> *)parseAuthInfosWithJSON:(NSDictionary *)json accessKey:(NSString *)accessKey
{
    NSString *keyPath = [NSString stringWithFormat:@"data.packages.%@", accessKey];
    // Check the fetched json.
    if (![[json objectForKey:@"data"] isKindOfClass:NSDictionary.class] ||
        ![[json valueForKeyPath:@"data.packages"] isKindOfClass:NSDictionary.class] ||
        ![[json valueForKeyPath:keyPath] isKindOfClass:NSArray.class]) {
         [[HMDUserExceptionTracker sharedTracker] trackCurrentThreadLogExceptionType:@"BridgeAuthFetchedDataError" skippedDepth:0 customParams:@{@"json" : [json description] ?: @""} filters:nil callback:nil];
        return nil;
    }
    NSMutableArray<IESBridgeAuthPackage *> *packages = [NSMutableArray array];
    NSArray<NSDictionary *> *dicts = [json valueForKeyPath:keyPath];
    [dicts enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:NSDictionary.class]) {
            IESBridgeAuthPackage *package = [[IESBridgeAuthPackage alloc] initWithDictionary:obj];
            if (package) {
                [packages addObject:package];
            }
        }
    }];
    return [packages copy];
}

#pragma mark - Instance Methods

- (void)registerMethod:(NSString *)method withAuthType:(IESPiperAuthType)authType
{
    //If the method has been in the overriddenMethodPackage fetched from Gecko, there's no need to register because the authType of the method in overriddenMethodPackage has been set.
    if (self.authPackage && self.authPackage.overriddenMethodPackage){
        if ([self.authPackage.overriddenMethodPackage containsMethodName:method]){
            return;
        }
    }
    
    [self.methodSetLock lock];
    switch (authType) {
        case IESPiperAuthPublic:
            [self.publicMethods addObject:method];
            break;
        case IESPiperAuthPrivate:
            [self.privateMethods addObject:method];
            break;
        case IESPiperAuthProtected:
            [self.protectedMethods addObject:method];
            break;
        case IESPiperAuthSecure:
            [self.secureMethods addObject:method];
            break;
        default:
            BDAssert(NO, @"Unsupported auth type: %@", @(authType));
            break;
    }
    [self.methodSetLock unlock];
}

- (BOOL)isAuthorizedMethod:(NSString *)method forURL:(NSURL *)url
{
    if (method.length == 0 || url.absoluteString.length == 0) {
        return NO;
    }
    if ([self.delegate respondsToSelector:@selector(authManager:isAuthorizedMethod:success:forURL:stage:list:)]) {
        [self.delegate authManager:self isAuthorizedMethod:method success:NO forURL:url stage:@"jsb_auth_start" list:nil];
    }
    if (self.isBypassJSBAuthEnabled) {
        return YES;
    }
    
    url = [self strippedURL:url];
    
    BOOL isAuthorized = NO;
    if ([self.delegate respondsToSelector:@selector(authManager:isAuthorizedMethod:forURL:)]) {
        isAuthorized = [self.delegate authManager:self isAuthorizedMethod:method forURL:url];
    }
    if (isAuthorized) {
        if ([self.delegate respondsToSelector:@selector(authManager:isAuthorizedMethod:success:forURL:stage:list:)]) {
            [self.delegate authManager:self isAuthorizedMethod:method success:isAuthorized forURL:url stage:@"open_jsb_auth_" list:nil];
        }
        return YES;
    }

    NSMutableSet<NSString *> *authorizedMethods = [NSMutableSet set];
    NSMutableSet<NSString *> *includedMethods = [NSMutableSet set];
    NSMutableSet<NSString *> *excludedMethods = [NSMutableSet set];
    IESPiperAuthType authGroup = IESPiperAuthPublic;
    [self updateAuthGroup:&authGroup includedMethods:includedMethods excludedMethods:excludedMethods forURL:url];
    
    // Collect all authorized methods according to the group to which the `url` is belong.
    // authGroup can only be one of IESPiperAuthPublic || IESPiperAuthProtected || IESPiperAuthPrivate
    [self.methodSetLock lock];
    if (authGroup >= IESPiperAuthPublic) {
        [authorizedMethods addObjectsFromArray:[self.publicMethods allObjects]];
    }
    if (authGroup >= IESPiperAuthProtected) {
        [authorizedMethods addObjectsFromArray:[self.protectedMethods allObjects]];
    }
    if (authGroup >= IESPiperAuthPrivate) {
        [authorizedMethods addObjectsFromArray:[self.privateMethods allObjects]];
    }
    [self.methodSetLock unlock];

    // Add/remove the additional included/excluded methods.
    [authorizedMethods unionSet:[includedMethods copy]];
    [authorizedMethods minusSet:[excludedMethods copy]];
    
    if ([self.delegate respondsToSelector:@selector(authManager:isAuthorizedMethod:success:forURL:stage:list:)]) {
        [self.delegate authManager:self isAuthorizedMethod:method success:[authorizedMethods containsObject:method] forURL:url stage:@"jsb_auth" list:nil];
    }
    return [authorizedMethods containsObject:method];
}

- (IESPiperAuthType)authGroupForURL:(NSURL *)url
{
    if (url.absoluteString.length == 0) {
        return IESPiperAuthPublic;
    }
    if (self.isBypassJSBAuthEnabled) {
        return IESPiperAuthPrivate;
    }
    
    IESPiperAuthType authGroup = IESPiperAuthPublic;
    [self updateAuthGroup:&authGroup includedMethods:nil excludedMethods:nil forURL:[self strippedURL:url]];
    return authGroup;
}

- (NSArray<NSString *> *)innerDomains
{
    return [self.privateDomains allObjects];
}

#pragma mark - Helpers

- (NSURL *)strippedURL:(NSURL *)url
{
    if (p_boeHostSuffix.length == 0) {
        return url;
    }
    
    NSURLComponents *urlComponents = [NSURLComponents componentsWithString:url.absoluteString];
    if ([urlComponents.host hasSuffix:p_boeHostSuffix]) {
        urlComponents.host = [urlComponents.host substringToIndex:(urlComponents.host.length - p_boeHostSuffix.length)];
    }
    return urlComponents.URL;
}

- (void)updateAuthGroup:(IESPiperAuthType *)authGroup
        includedMethods:(NSMutableSet<NSString *> *)includedMethods
        excludedMethods:(NSMutableSet<NSString *> *)excludedMethods
                 forURL:(NSURL *)url
{
    if (url.absoluteString.length == 0) {
        return;
    }
    
    // Set default auth group for 'file' scheme.
    if ([url.scheme isEqualToString:@"file"]) {
        *authGroup = IESPiperAuthPrivate;
        return;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IESBridgeAuthManager.sharedManager.usedAuthInfosBeforeConfiguring = YES;
    });
    
    [self.class p_fetchAllAuthInfosIfNeeded];

    // Strip URL query to make regex matching more efficient.
    NSString *urlStringWithoutQuery = [[url.absoluteString componentsSeparatedByString:@"?"] firstObject];
    NSURL *strippedURL = urlStringWithoutQuery ? [NSURL URLWithString:urlStringWithoutQuery] : url;
    NSString *urlString = strippedURL.absoluteString;
    
    // Append trailing slash if needed.
    if (strippedURL.path.length == 0 && ![urlString hasSuffix:@"/"]) {
        urlString = [urlString stringByAppendingString:@"/"];
    }

    // Merge all rules whose regex pattern matches the `url`.
    NSString *sld = [self secondLevelDomainForURL:strippedURL];
    if (!sld) {
        return;
    }
    NSArray<IESBridgeAuthRule *> *rules = self.authRules[sld];
    [rules enumerateObjectsUsingBlock:^(IESBridgeAuthRule *obj, NSUInteger idx, BOOL *stop) {
        if (obj.pattern.length == 0) {
            return;
        }
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:obj.pattern options:0 error:nil];
        NSTextCheckingResult *result = [regex firstMatchInString:urlString options:0 range:NSMakeRange(0, urlString.length)];
        if (result) {
            *authGroup = MAX(*authGroup, obj.group);
            if (obj.includedMethods && includedMethods) {
                [includedMethods addObjectsFromArray:obj.includedMethods];
            }
            if (obj.excludedMethods && excludedMethods) {
                [excludedMethods addObjectsFromArray:obj.excludedMethods];
            }
        }
    }];
}

- (NSString *)secondLevelDomainForURL:(NSURL *)url
{
    if ([url.absoluteString isEqualToString:@"about:blank"]) {
        return nil;
    }
    
    NSString *host = url.host ?: [[url.path componentsSeparatedByString:@"/"] firstObject];
    NSArray<NSString *> *components = [host componentsSeparatedByString:@"."];
    NSString *result = nil;
    if (components.count >= 2) {
        result = [[components subarrayWithRange:NSMakeRange(components.count - 2, 2)] componentsJoinedByString:@"."];
    } else {
        result = host;
    }
    BDAssert(!!(result), @"Invalid second level domain for URL: `%@`", url);
    return result;
}

- (void)updateAuthRules
{
    NSMutableDictionary<NSString *, NSArray<IESBridgeAuthRule *> *> *authRules = [NSMutableDictionary dictionary];
    void(^enumerateBlock)(id, id, BOOL *) = ^(NSString *key, NSArray<IESBridgeAuthRule *> *rules, BOOL *stop) {
        authRules[key] = [(authRules[key] ?: @[]) arrayByAddingObjectsFromArray:rules];
    };
    
    // Add from private auth rules.
    NSMutableDictionary *privateAuthRules = [NSMutableDictionary dictionary];
    [self.privateDomains enumerateObjectsUsingBlock:^(NSString *obj, BOOL *stop) {
        NSURL *url = [NSURL URLWithString:obj];
        NSString *sld = [self secondLevelDomainForURL:url];
        if (!sld) {
            return;
        }
        NSString *escapedDomain = [NSRegularExpression escapedPatternForString:obj];
        NSString *pattern = [NSString stringWithFormat:@"^https?:\\/\\/([0-9A-Za-z_\\-~]+\\.)*?%@\\/", escapedDomain];
        IESBridgeAuthRule *rule = [[IESBridgeAuthRule alloc] initWithPattern:pattern group:IESPiperAuthPrivate];
        privateAuthRules[sld] = [(privateAuthRules[sld] ?: @[]) arrayByAddingObject:rule];
    }];
    [privateAuthRules enumerateKeysAndObjectsUsingBlock:enumerateBlock];
    
    // Add from `packages`.
    [self.authPackage.content enumerateKeysAndObjectsUsingBlock:enumerateBlock];
    
    // Update the global auth rules.
    self.authRules = [authRules copy];
}

// Use the overriddenMethodPackage fetched from Gecko to update methods' authType.
- (void)updateMethodAuthTypes
{
    NSMutableSet *allOverriddenMethods = [[NSMutableSet alloc] init];
    [allOverriddenMethods unionSet:self.authPackage.overriddenMethodPackage.publicMethods];
    [allOverriddenMethods unionSet:self.authPackage.overriddenMethodPackage.protectedMethods];
    [allOverriddenMethods unionSet:self.authPackage.overriddenMethodPackage.privateMethods];
    
    [self.methodSetLock lock];
    [self.publicMethods minusSet:allOverriddenMethods];
    [self.protectedMethods minusSet:allOverriddenMethods];
    [self.privateMethods minusSet:allOverriddenMethods];
    [self.publicMethods unionSet:self.authPackage.overriddenMethodPackage.publicMethods];
    [self.protectedMethods unionSet:self.authPackage.overriddenMethodPackage.protectedMethods];
    [self.privateMethods unionSet:self.authPackage.overriddenMethodPackage.privateMethods];
    [self.methodSetLock unlock];
}

+ (NSDictionary *)getRequestParamsWithAccessKey:(NSString *)accessKey commonParams:(NSDictionary *)commonParams extraChannels:(NSArray<NSString *> *)extraChannels{
    NSDictionary *common = ({
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@"aid"] = @([commonParams[@"aid"] integerValue]);
        dict[@"app_version"] = commonParams[@"app_version"];
        dict[@"os"] = @(1);
        dict[@"device_id"] = commonParams[@"device_id"];
        [dict copy];
    });
    
    NSMutableArray<NSDictionary *> *configs = [NSMutableArray arrayWithObject:@{
        @"channel" : IESBridgeAuthInfoChannel,
        @"local_version" : @(0)
    }];
    if (!IWK_IS_EMPTY_ARRAY(extraChannels)) {
        [extraChannels enumerateObjectsUsingBlock:^(NSString * _Nonnull channel, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!IWK_IS_EMPTY_STRING(channel)) {
                [configs addObject:@{
                    @"channel" : channel,
                    @"local_version" : @(0)
                }];
            }
        }];
    }
    
    NSDictionary *deployment = ({
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[accessKey] = configs;
        [dict copy];
    });
    
    NSDictionary *params = ({
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[@"common"] = common;
        dict[@"deployment"] = deployment;
        [dict copy];
    });
    return params;
}

#pragma mark - Accessors

// Share the same variable among different namespaces.
static BOOL p_fetchedAuthInfos = NO;
static BOOL p_fetchingAuthInfos = NO;
static BOOL p_usedAuthInfosBeforeConfiguring = NO;
static BOOL p_builtinAuthInfosEnabled = NO;
static BOOL p_bypassJSBAuthEnabled = NO;

- (void)setFetchedAuthInfos:(BOOL)fetchedAuthInfos
{
    p_fetchedAuthInfos = fetchedAuthInfos;
}

- (BOOL)hasFetchedAuthInfos
{
    return p_fetchedAuthInfos;
}

- (void)setFetchingAuthInfos:(BOOL)fetchingAuthInfos
{
    p_fetchingAuthInfos = fetchingAuthInfos;
}

- (BOOL)isFetchingAuthInfos
{
    return p_fetchingAuthInfos;
}

- (void)setUsedAuthInfosBeforeConfiguring:(BOOL)usedAuthInfosBeforeConfiguring
{
    p_usedAuthInfosBeforeConfiguring = usedAuthInfosBeforeConfiguring;
}

- (BOOL)hasUsedAuthInfosBeforeConfiguring
{
    return p_usedAuthInfosBeforeConfiguring;
}

- (void)setBuiltinAuthInfosEnabled:(BOOL)builtinAuthInfosEnabled
{
    p_builtinAuthInfosEnabled = builtinAuthInfosEnabled;
}

- (BOOL)isBuiltinAuthInfosEnabled
{
    return p_builtinAuthInfosEnabled;
}

- (void)setBypassJSBAuthEnabled:(BOOL)bypassJSBAuthEnabled
{
    p_bypassJSBAuthEnabled = bypassJSBAuthEnabled;
}

- (BOOL)isBypassJSBAuthEnabled
{
    return p_bypassJSBAuthEnabled;
}

- (BOOL)hasCachedAuthInfos
{
    return !![NSUserDefaults.standardUserDefaults objectForKey:IWKBridgeAuthInfosKey];
}

- (void)setAuthPackage:(IESBridgeAuthPackage *)authPackage
{
    _authPackage = authPackage;
    [self updateAuthRules];
    [self updateMethodAuthTypes];
}

- (void)addPrivateDomains:(NSArray<NSString *> *)privateDomains
{
    [self.privateDomains addObjectsFromArray:[privateDomains copy]];
    [self updateAuthRules];
}

+ (IESBridgeAuthRequestParams *)requestParams
{
    return objc_getAssociatedObject(self, _cmd);
}

+ (void)setRequestParams:(IESBridgeAuthRequestParams *)requestParams
{
    objc_setAssociatedObject(self, @selector(requestParams), requestParams, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

