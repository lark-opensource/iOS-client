//
//  OKSectionFunction.m
//  OneKit
//
//  Created by bob on 2020/10/2.
//

#import "OKSectionFunction.h"
#import <mach-o/getsect.h>
#import <mach-o/loader.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <mach-o/ldsyms.h>

@interface _OKFunctionData : NSObject
@end

@implementation _OKFunctionData {
    const void *_function;
}

- (instancetype)initWithPointer:(const void *)pointer {
    if (self = [super init]) {
        _function = pointer;
    }
    
    return self;
}

- (void)start {
    if (_function) {
        ((void (*)(void))_function)();
    }
}

@end

typedef struct _OKFunctionNode {
    OKFunction* dataArray;
    unsigned long size;
    struct _OKFunctionNode *next;
    struct _OKFunctionNode *head;
} OKFunctionNode;

static OKFunctionNode *_NODE;

@interface OKSectionFunction ()

@property (atomic, strong) NSMutableDictionary<NSString *, NSMutableArray *> *keyFunctions;
- (void)addFunction:(const void *)pointer forKey:(NSString *)key;

@end

static void OKParseNode() {
    if (_NODE == NULL) {
        return;
    }
    OKFunctionNode *head = _NODE->head;
    OKFunctionNode *node = head;
    while (node != NULL) {
        OKFunction *dataArray = node->dataArray;
        unsigned long counter = node->size;
        for(int idx = 0; idx < counter; ++idx) {
            OKFunction data = dataArray[idx];
            NSString *key = [NSString stringWithUTF8String:data.key];
            const void * function = data.function;
            [[OKSectionFunction sharedInstance] addFunction:function forKey:key];
        }
        node = node->next;
    }
    _NODE = NULL;
}

static void OKReadFunctions(char *sectionName, const struct mach_header *mhp) {
    unsigned long size = 0;
#ifndef __LP64__
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp, SEG_DATA, sectionName, &size);
#else
    const struct mach_header_64 *mhp64 = (const struct mach_header_64 *)mhp;
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp64, SEG_DATA, sectionName, &size);
#endif
    OKFunction *dataArray = (OKFunction *)memory;
    unsigned long counter = size/sizeof(OKFunction);
    
    OKFunctionNode *node = (OKFunctionNode*)malloc(sizeof(OKFunctionNode));
    node->dataArray = dataArray;
    node->size = counter;
    node->next = NULL;
    node->head = NULL;
    if (_NODE != NULL) {
        node->head = _NODE->head;
        _NODE->next = node;
    } else {
        node->head = node;
    }
    _NODE = node;
    
    /// next runloop for oc method
    dispatch_async(dispatch_get_main_queue(), ^{
        OKParseNode();
    });
}

static void dyld_function_callback(const struct mach_header *mhp, intptr_t vmaddr_slide)
{
    Dl_info info;
    if (dladdr(mhp, &info) == 0) {
        return;
    }
    OKReadFunctions("__OneKitFunction", mhp);
}


//__attribute__((constructor)) void okFunctionProphet() {
//    _dyld_register_func_for_add_image(dyld_function_callback);
//}


@implementation OKSectionFunction

+ (void)initialize {
    _dyld_register_func_for_add_image(dyld_function_callback);
    OKParseNode();
}

+ (instancetype)sharedInstance {
    static OKSectionFunction *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.keyFunctions = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)addFunction:(const void *)pointer forKey:(NSString *)key {
    if (pointer == nil || key == nil) {
        return;
    }
    
    NSMutableArray *functions = [self.keyFunctions objectForKey:key];
    if (functions == nil) {
        functions = [NSMutableArray new];
        [self.keyFunctions setValue:functions forKey:key];
    }
    [functions addObject:[[_OKFunctionData alloc] initWithPointer:pointer]];
}

- (void)excuteFunctionsForKey:(NSString *)key {
    if (key == nil) {
        return;
    }
    
    NSArray<_OKFunctionData *> *functions = [self.keyFunctions objectForKey:key].copy;
    if (functions == nil) {
        return;
    }
    [functions enumerateObjectsUsingBlock:^(_OKFunctionData *function, NSUInteger idx, BOOL * stop) {
        [function start];
    }];
}

- (void)excuteSwiftFunctionsForKey:(NSString *)key {
    
}

@end
