//
//  BDDYCURL.m
//  BDDynamically
//
//  Created by zuopengliu on 22/6/2018.
//

#import "BDDYCURL.h"
#import "BDDYCNSURLHelper.h"



static NSString * const kBDDYCScheme = @"bc-alpha-ing";

#define KBDDYCSchemeActionStart     @"start"
#define KBDDYCSchemeActionClose     @"close"
#define KBDDYCSchemeActionFetch     @"fetch"
#define KBDDYCSchemeActionOffline   @"offline"
#define KBDDYCSchemeActionOpenVC    @"open_vc"

@interface BDDYCURL ()
@property (nonatomic, strong) NSURL *nsurl;
@end
@implementation BDDYCURL

+ (NSString *)scheme
{
    return kBDDYCScheme;
}

#pragma mark - creation

+ (instancetype)DYCURLWithNSURL:(NSURL *)url
{
    return [[self alloc] initWithNSURL:url];
}

- (instancetype)initWithNSURL:(NSURL *)url
{
    if (!url) return nil;
    NSString *scheme = url.scheme;
    NSString *host   = url.host;
    NSString *path   = url.path;
    NSString *params = BDDYCParseQueryParametersFromURL(url);
    NSArray *arr = [path componentsSeparatedByString:@"/"];
    NSString *business = arr.count > 0 ? [arr firstObject] : nil;
    NSString *action = [arr lastObject] ? : path;
    
    return [self initWithScheme:scheme
                        product:host
                       business:business
                         action:action
                     parameters:params];
}

+ (instancetype)DYCURLWithProduct:(NSString *)product
                         business:(NSString *)business
                           action:(NSString *)action
                       parameters:(NSDictionary *)params
{
    return [[self alloc] initWithProduct:product
                                business:business
                                  action:action
                              parameters:params];
}

- (instancetype)initWithProduct:(NSString *)product
                       business:(NSString *)business
                         action:(NSString *)action
                     parameters:(NSDictionary *)params
{
    return [self initWithScheme:kBDDYCScheme
                        product:product
                       business:business
                         action:action
                     parameters:params];
}

- (instancetype)initWithScheme:(NSString *)scheme
                       product:(NSString *)product
                      business:(NSString *)business
                        action:(NSString *)action
                    parameters:(NSDictionary *)params
{
    if ((self = [super init])) {
        _scheme     = [scheme copy];
        _product    = [product copy];
        _business   = [business copy];
        _action     = [action copy];
        _parameters = [params copy];
        
        if (!_product) _product = @"better_0000";
    }
    return self;
}

#pragma mark -

- (NSURL *)toNSURL
{
    if (_nsurl) return _nsurl;
    
    NSParameterAssert(_product && @"Must assign product name");
    NSParameterAssert(_action && @"Must assign url action");
    NSMutableString *mutString = [NSMutableString stringWithFormat:@"%@://%@", _scheme, _product ? : @"unknown_product"];
    if (_business) [mutString appendFormat:@"/%@", _business];
    [mutString appendFormat:@"/%@", _action];
    
    NSString *urlString = BDDYCURLAppendQueryParameters(mutString, _parameters);
    _nsurl = [NSURL URLWithString:urlString];
    
    return _nsurl;
}

#pragma mark - check

- (BOOL)canHandle
{
    return (self.scheme && [self.scheme isEqualToString:kBDDYCScheme]);
}

+ (BOOL)canHandleURL:(NSURL *)url
{
    if (!url || ![url isKindOfClass:[NSURL class]]) return NO;
    NSString *scheme = url.scheme;
    return (scheme && [scheme isEqualToString:kBDDYCScheme]);
}

#pragma mark - Setter/Getter

@end

#pragma mark -

@implementation BDDYCURL (StakeSchemes)

+ (instancetype)startDYCURL
{
    return [self DYCURLWithProduct:nil
                          business:nil
                            action:KBDDYCSchemeActionStart
                        parameters:nil];
}

+ (instancetype)closeDYCURL
{
    return [self DYCURLWithProduct:nil
                          business:nil
                            action:KBDDYCSchemeActionClose
                        parameters:nil];
}

+ (instancetype)fetchDYCURL
{
    return [self DYCURLWithProduct:nil
                          business:nil
                            action:KBDDYCSchemeActionFetch
                        parameters:nil];
}

- (BOOL)isStartScheme
{
    return [self.action.lowercaseString isEqualToString:KBDDYCSchemeActionStart];
}

- (BOOL)isCloseScheme
{
    return [self.action.lowercaseString isEqualToString:KBDDYCSchemeActionClose];
}

- (BOOL)isFetchScheme
{
    return [self.action.lowercaseString isEqualToString:KBDDYCSchemeActionFetch];
}

@end
