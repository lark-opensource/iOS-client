//
//  OPArguement.h
//  OPSDK
//
//  Created by Nicholas Tau on 2020/12/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//to indicate three type of argument
//like _Nullable, NotNull, and ignore「treat as nullable」
typedef NS_ENUM(NSUInteger, OPNullability) {
    OPNullabilityUnspecified,
    OPNullable,
    OPNonnullable,
};

@interface OPArguement : NSObject
- (instancetype)initWithType:(NSString *)type
                 nullability:(OPNullability)nullability
                      unused:(BOOL)unused;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *type;
@property (nonatomic, readonly) OPNullability nullability;
@property (nonatomic, readonly) BOOL unused;
@end

NSString *OPParseMethodSignature(const char *input, NSArray<OPArguement *> **arguments);
SEL selectorForType(NSString *type);

NS_ASSUME_NONNULL_END
