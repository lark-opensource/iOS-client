//
//  StingerParams.m
//  Stinger
//
//  Created by Assuner on 2018/1/10.
//  Copyright © 2018年 Assuner. All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "StingerMacro.h"
#import "StingerParams.h"

@interface StingerParams ()
@property (nonatomic, strong) NSString *types;
@property (nonatomic) SEL sel;
@property (nonatomic) IMP originalIMP;
@property (nonatomic) void **args;
@property (nonatomic) NSArray *argumentTypes;
@property (nonatomic) NSArray *arguments;
@property (nonatomic, nullable) NSInvocation *invocation;
@property (nonatomic, getter=isValid) BOOL valid;
@end

@implementation StingerParams

- (instancetype)init {
    NSAssert(NO, @"StingerParam should not be initialized from -[StingerParams init]");
    DEBUG_RETURN(nil);
}

- (instancetype)initWithType:(NSString *)types originalIMP:(IMP)imp sel:(SEL)sel args:(void **)args argumentTypes:(NSArray *)argumentTypes {
    if (self = [super init]) {
        _types = types;
        _sel = sel;
        _originalIMP = imp;
        _args = args;
        _argumentTypes = argumentTypes;
        _valid = YES;
        [self st_genarateArguments];
    }
    return self;
}

- (id)slf {
    void **slfPointer = _args[0];
    return (__bridge id)(*slfPointer);
}

- (SEL)sel {
    return _sel;
}

- (NSArray *)arguments {
    return _arguments;
}

- (NSString *)typeEncoding {
    return _types;
}

- (void)_internalGenerateInvocation {
    if(self.valid && self.invocation == nil) {
        NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:_types.UTF8String];
        NSInteger count = signature.numberOfArguments;
        NSInvocation *originalInvocation = [NSInvocation invocationWithMethodSignature:signature];
        for (int i = 0; i < count; i ++) {
            void * _Nonnull eachArgument = _args[i];
            
            #if __arm64__ && __LP64__
            uint64_t argumentAddress = (uint64_t)eachArgument;
            #endif
            
            #if __arm64__ && __LP64__
            COMPILE_ASSERT(!VM_ADDRESS_CONTAIN(UINT64_C(0x0)));
            COMPILE_ASSERT(!VM_ADDRESS_CONTAIN(UINT64_C(0x100000000)));
            COMPILE_ASSERT( VM_ADDRESS_CONTAIN(UINT64_C(0x100000000 + 1)));
            COMPILE_ASSERT( VM_ADDRESS_CONTAIN(UINT64_C(0xFFFFFFFFF - 1)));
            COMPILE_ASSERT(!VM_ADDRESS_CONTAIN(UINT64_C(0xFFFFFFFFF)));
            COMPILE_ASSERT(!VM_ADDRESS_CONTAIN(UINT64_MAX));
            #else
            COMPILE_ASSERT( VM_ADDRESS_CONTAIN(UINT64_C(0x0)));
            COMPILE_ASSERT( VM_ADDRESS_CONTAIN(UINT64_C(0x100000000)));
            COMPILE_ASSERT( VM_ADDRESS_CONTAIN(UINT64_C(0x100000000 + 1)));
            COMPILE_ASSERT( VM_ADDRESS_CONTAIN(UINT64_C(0xFFFFFFFFF - 1)));
            COMPILE_ASSERT( VM_ADDRESS_CONTAIN(UINT64_C(0xFFFFFFFFF)));
            COMPILE_ASSERT( VM_ADDRESS_CONTAIN(UINT64_MAX));
            #endif
            
            #if __arm64__ && __LP64__
            if(!VM_ADDRESS_CONTAIN(argumentAddress)) {
                self.valid = NO;
                DEBUG_RETURN_NONE;
            }
            #endif
            [originalInvocation setArgument:eachArgument atIndex:i];
        }
        self.invocation = originalInvocation;
    }
}

- (void)preGenerateInvocationIfNeed {
    [self _internalGenerateInvocation];
}

- (void)invokeAndGetOriginalRetValue:(void * _Nullable)retLoc {
    [self _internalGenerateInvocation];
    
    NSInvocation *originalInvocation = self.invocation;
    if(originalInvocation == nil) {
        self.valid = NO;
        DEBUG_RETURN_NONE;
    }
    
    /// invokeUsingIMP: is a private api
    NSString *selectorStr = @"aW52b2tlVXNpbmdJTVA6";
    DEBUG_ASSERT([[[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:selectorStr options:0] encoding:NSUTF8StringEncoding] isEqualToString:@"invokeUsingIMP:"]);
    NSData *data = [[NSData alloc] initWithBase64EncodedString:selectorStr options:0];
    NSString *selectorName = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    SEL selector = NSSelectorFromString(selectorName);
    void (*action)(id, SEL, IMP) = (void (*)(id, SEL, IMP))objc_msgSend;
    action(originalInvocation, selector, _originalIMP);
    
    if (originalInvocation.methodSignature.methodReturnLength && !(retLoc == NULL)) {
        [originalInvocation getReturnValue:retLoc];
    }
}

#pragma - mark Private

- (void)st_genarateArguments {
    NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity:_argumentTypes.count];
    for (NSUInteger i = 2; i < _argumentTypes.count; i++) {
        id argument = [self st_argumentWithType:_argumentTypes[i] index:i];
        [args addObject:argument ?: NSNull.null];
    }
    _arguments = [args copy];
}

- (id)st_argumentWithType:(NSString *)type index:(NSUInteger)index {
    const char *argType = type.UTF8String;
    // Skip const type qualifier.
    if (argType[0] == _C_CONST) argType++;

#define WRAP_AND_RETURN(type) do { type val = 0; val = *((type *)_args[index]); return @(val); } while (0)
    if (strcmp(argType, @encode(id)) == 0 || strcmp(argType, @encode(Class)) == 0) {
        void **objPointer = _args[index];
        return (__bridge id)(*objPointer);
    } else if (strcmp(argType, @encode(SEL)) == 0) {
        SEL selector = *((SEL *)_args[index]);
        return NSStringFromSelector(selector);
    } else if (strcmp(argType, @encode(char)) == 0) {
        WRAP_AND_RETURN(char);
    } else if (strcmp(argType, @encode(int)) == 0) {
        WRAP_AND_RETURN(int);
    } else if (strcmp(argType, @encode(short)) == 0) {
        WRAP_AND_RETURN(short);
    } else if (strcmp(argType, @encode(long)) == 0) {
        WRAP_AND_RETURN(long);
    } else if (strcmp(argType, @encode(long long)) == 0) {
        WRAP_AND_RETURN(long long);
    } else if (strcmp(argType, @encode(unsigned char)) == 0) {
        WRAP_AND_RETURN(unsigned char);
    } else if (strcmp(argType, @encode(unsigned int)) == 0) {
        WRAP_AND_RETURN(unsigned int);
    } else if (strcmp(argType, @encode(unsigned short)) == 0) {
        WRAP_AND_RETURN(unsigned short);
    } else if (strcmp(argType, @encode(unsigned long)) == 0) {
        WRAP_AND_RETURN(unsigned long);
    } else if (strcmp(argType, @encode(unsigned long long)) == 0) {
        WRAP_AND_RETURN(unsigned long long);
    } else if (strcmp(argType, @encode(float)) == 0) {
        WRAP_AND_RETURN(float);
    } else if (strcmp(argType, @encode(double)) == 0) {
        WRAP_AND_RETURN(double);
    } else if (strcmp(argType, @encode(BOOL)) == 0) {
        WRAP_AND_RETURN(BOOL);
    } else if (strcmp(argType, @encode(bool)) == 0) {
        WRAP_AND_RETURN(BOOL);
    } else if (strcmp(argType, @encode(char *)) == 0) {
        WRAP_AND_RETURN(const char *);
    } else if (strcmp(argType, @encode(void (^)(void))) == 0) {
        void **blockPointer = _args[index];
        __unsafe_unretained id block = (__bridge id)(*blockPointer);
        return [block copy];
    } else {
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment(argType, &valueSize, NULL);

        unsigned char valueBytes[valueSize];
        memcpy(valueBytes, _args[index], valueSize);
        
        return [NSValue valueWithBytes:valueBytes objCType:argType];
    }
    return nil;
#undef WRAP_AND_RETURN
}

@end
