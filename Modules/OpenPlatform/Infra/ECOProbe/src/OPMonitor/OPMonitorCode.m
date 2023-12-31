//
//  OPMonitorCode.m
//  LarkOPInterface
//
//  Created by yinyuan on 2020/5/21.
//

#import "OPMonitorCode.h"

static NSInteger const kOPMonitorCodeVersion = 1;
static NSString * const kOPMonitorCodeDefaultDomain = @"global";

@interface OPMonitorCode()

@property (nonatomic, assign, readwrite) OPMonitorLevel level;

@property (nonatomic, strong, nonnull, readwrite) NSString *domain;

@property (nonatomic, assign, readwrite) NSInteger code;

@property (nonatomic, strong, nonnull, readwrite) NSString *ID;

@property (nonatomic, strong, nonnull, readwrite) NSString *message;

@end

@implementation OPMonitorCode

- (instancetype _Nonnull)initWithDomain:(NSString * _Nonnull)domain
                                   code:(NSInteger)code
                                  level:(OPMonitorLevel)level
                                message:(NSString * _Nonnull)message
{
    self = [super init];
    if (self) {
        NSAssert(domain && message, @"domain and message should not be nil");
        self.domain = domain ?: @"";
        self.code = code;
        self.level = level;
        self.message = message ?: @"";

        self.ID = [self generateID];    // 自动生成 ID
    }
    return self;
}

- (instancetype)initWithCode:(id<OPMonitorCodeProtocol>)code {
    self = [super init];
    if (self) {
        NSAssert(code, @"code should not be nil");
        self.domain = code.domain;
        self.code = code.code;
        self.level = code.level;
        self.message = code.message;
        self.ID = [self generateID];
    }
    return self;
}

/// 生成ID {version}-{domain}-{code}
- (NSString * _Nonnull)generateID {
    return [NSString stringWithFormat:@"%@-%@-%@", @(kOPMonitorCodeVersion), self.domain, @(self.code)];
}

/// {version}-{domain}-{code}-{message}
- (NSString *)description {
    return [NSString stringWithFormat:@"%@-%@", self.ID, self.message];
}

/// 支持 equal 判等
- (BOOL)isEqual:(id)object {
    if (!object) {
        return NO;
    }
    if (![object isKindOfClass:OPMonitorCode.class]) {
        return NO;
    }
    return [self.ID isEqualToString:((OPMonitorCode *)object).ID];
}

/// 支持 hash 判等
- (NSUInteger)hash {
    return self.ID.hash;
}

@end
