//
//  GAIAEngine.m
//  Pods-Gaia
//
//  Created by 李琢鹏 on 2019/1/8.
//

#import "GAIAEngine.h"
#import <dlfcn.h>
#import <mach-o/getsect.h>
#import <mach-o/dyld.h>
#import <pthread.h>


static NSMutableDictionary<NSString *, NSMutableArray<GAIATask *> *> *gaia_tasks;
#if DEBUG
static NSMutableDictionary<NSString *, NSString *> *gaia_loadedMethods;
#endif




@interface GAIAEngine ()

+ (instancetype)sharedInstance;

@property(nonatomic, strong) NSHashTable *observers;

@end

@interface GAIATask()

@property (nonatomic, assign) BOOL repeatable;

+ (GAIATask *)taskWithData:(GAIAData)data;
- (void)start;
- (void)startWithObject:(id)object;

@end

@interface _GAIAFunction()

- (instancetype)initWithPointer:(const void *)pointer NS_DESIGNATED_INITIALIZER;

@end

@interface _GAIAFunctionInfoData()

- (instancetype)initWithPointer:(const void *)pointer NS_DESIGNATED_INITIALIZER;

@end

@interface _GAIAObjCMethod()

- (instancetype)initWithPointer:(const void *)pointer NS_DESIGNATED_INITIALIZER;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
@implementation GAIATask


+ (GAIATask *)taskWithData:(GAIAData)data {
    GAIATask *task;
    switch (data.type) {
        case GAIATypeFunction:
            task = [[_GAIAFunction alloc] initWithPointer:data.value];
            break;
        case GAIATypeObjCMethod:
            task = [[_GAIAObjCMethod alloc] initWithPointer:data.value];
            break;
        case GAIATypeFunctionInfo:
            task = [[_GAIAFunctionInfoData alloc] initWithPointer:data.value];
            break;
        default:
            NSAssert(NO, @"Unrecognized gaia data type: %@", @(data.type));
            break;
    }
    task.repeatable = data.repeatable;
    return task;
}

- (void)start {
    [NSException raise:NSGenericException format:@"'start' should be implementated in subclass."];
}

- (void)startWithObject:(id)object {
    [NSException raise:NSGenericException format:@"'startWithObject:' should be implementated in subclass."];
}

@end

@implementation _GAIAFunction {
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

- (void)startWithObject:(id)object {
    if (_function) {
        ((void (*)(id))_function)(object);
    }
}

@end

@implementation _GAIAFunctionInfoData {
    GAIAFunctionInfo *_functionInfoPointer;
}


- (instancetype)initWithPointer:(const void *)pointer {
    if (self = [super init]) {
        _functionInfoPointer = (GAIAFunctionInfo *)pointer;
    }
    return self;
}

- (void)start {
    if (_functionInfoPointer->function) {
        ((void (*)(void))_functionInfoPointer->function)();
    }
}

- (void)startWithObject:(id)object {
    if (_functionInfoPointer->function) {
        ((void (*)(id))_functionInfoPointer->function)(object);
    }
}

- (GAIAFunctionInfo)functionInfo {
    return *_functionInfoPointer;
}

@end

@implementation _GAIAObjCMethod {
    Class _class;
    SEL _selector;
}

- (instancetype)initWithPointer:(const void *)pointer {
    char *funcPointer = (char *)pointer;
    if (*(funcPointer) != '+'){
        NSAssert(NO, @"GAIA can only export class method.");
        return nil;
    }
    NSString *func = [NSString stringWithUTF8String:pointer];
    __auto_type components = [func componentsSeparatedByString:@" "];
    if (components.count != 2) {
        return nil;
    }
    if (self = [super init]) {
        NSRange range = [components[0] rangeOfString:@"("];
        NSString *className = nil;
        if (range.length > 0) {
            className = [components[0] substringWithRange:NSMakeRange(2, range.location - 2)];
            _class = NSClassFromString(className);
        }
        else {
            className = [components[0] stringByReplacingOccurrencesOfString:@"+[" withString:@""];
            _class = NSClassFromString(className);
        }
        _selector = NSSelectorFromString([components[1] stringByReplacingOccurrencesOfString:@"]" withString:@""]);
#if DEBUG
        NSString *method = [NSString stringWithFormat:@"+[%@ %@]", className, NSStringFromSelector(_selector)];
        if (!gaia_loadedMethods[method]) {
            gaia_loadedMethods[method] = func;
        }
        else {
            NSAssert(NO, @"Duplicated implementation of Gaia method: '%@' and '%@'.", gaia_loadedMethods[method], func);
        }
#endif
    }
    return self;
}
#pragma clang diagnostic pop

- (void)start {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([_class respondsToSelector:_selector]) {
        [_class performSelector:_selector];
    }
#pragma clang diagnostic pop
}

- (void)startWithObject:(id)object {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([_class respondsToSelector:_selector]) {
        [_class performSelector:_selector withObject:object];
    }
#pragma clang diagnostic pop
}

- (Class)classOfMethod {
    return _class;
}

- (SEL)selector {
    return _selector;
}

@end

@implementation GAIAEngine

static pthread_mutex_t _lock;
static pthread_mutexattr_t _attr;
static pthread_mutex_t _observerLock;

typedef struct _GAIADataNode {
    GAIAData* dataArray;
    unsigned long size;
    struct _GAIADataNode *next;
    struct _GAIADataNode *head;
} GAIADataNode;

GAIADataNode *_NODE;

static void load_image(const struct mach_header *mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (dladdr(mh, &info) == 0) {
        return;
    }
    const void *header = mh;
    unsigned long size;
    GAIAData *dataArray = (GAIAData *)getsectiondata(header, GAIASegmentName, GAIASectionName, &size);
    if (dataArray == NULL) {
        return;
    }
    // 不能在传入 _dyld_register_func_for_add_image 的函数中使用 OC 方法，否则可能会产生死锁，因此先将数据存在链表中，等函数执行完成后再转化为 OC 对象
    GAIADataNode *node = (GAIADataNode*)malloc(sizeof(GAIADataNode));
    node->dataArray = dataArray;
    node->size = size;
    node->next = NULL;
    node->head = NULL;
    pthread_mutex_lock(&_lock);
    if (_NODE != NULL) {
        node->head = _NODE->head;
        _NODE->next = node;
    }
    else {
        node->head = node;
    }
    _NODE = node;
    pthread_mutex_unlock(&_lock);
    // 通过 dl_open() 链接的动态库，在下一次 runloop 中执行解析
    dispatch_async(dispatch_get_main_queue(), ^{
        gaia_parse_node();
    });
}

static void gaia_parse_node() {
    pthread_mutex_lock(&_lock);
    if (_NODE == NULL) {
        pthread_mutex_unlock(&_lock);
        return;
    }
   //将链表中的数据转化为 OC 对象
    GAIADataNode *head = _NODE->head;
    GAIADataNode *node = head;
    while (node != NULL) {
        GAIAData *dataArray = node->dataArray;

        unsigned long size = node->size;
        size_t count = size / sizeof(GAIAData);
        for (size_t i = 0; i < count; i++) {
            GAIAData data = dataArray[i];
            NSString *key = [NSString stringWithUTF8String:data.key];
            GAIATask *task = [GAIATask taskWithData:data];
            if (!task) {
                return;
            }
            __auto_type array = gaia_tasks[key];
            if (!array) {
                array = [NSMutableArray array];
                gaia_tasks[key] = array;
            }
            [array addObject:task];
        }
        GAIADataNode *temp = node;
        node = node->next;
        free(temp);
    }
    _NODE = NULL;
    pthread_mutex_unlock(&_lock);
}

+ (instancetype)sharedInstance {
    static GAIAEngine *g = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g = [[GAIAEngine alloc] init];
    });
    return g;
}

+ (void)initialize {
    pthread_mutexattr_init(&_attr);
    pthread_mutexattr_settype(&_attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init(&_lock, &_attr);
    pthread_mutexattr_destroy(&_attr);
    gaia_tasks = NSMutableDictionary.new;
#if DEBUG
    gaia_loadedMethods = NSMutableDictionary.new;
#endif
    [self loadImage];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        pthread_mutex_init(&_observerLock, NULL);
    }
    return self;
}

+ (void)loadImage {
    _dyld_register_func_for_add_image(load_image);
    gaia_parse_node();
}


+ (NSArray<GAIATask *> *)tasksForKey:(NSString *)key {
    pthread_mutex_lock(&_lock);
    NSArray *taskArray = gaia_tasks[key].copy;
    pthread_mutex_unlock(&_lock);
    return taskArray;
}

+ (void)startTasksForKey:(NSString *)key {
    [[GAIAEngine sharedInstance] startTasksForKey:key];
}

+ (void)startSwiftTasksForKey:(NSString *)key {
//    [NSException raise:NSGenericException format:@"Import SwiftGaia to support this method."];
}

+ (void)startTasksForKey:(NSString *)key withObject:(id)object {
    [[GAIAEngine sharedInstance] startTasksForKey:key withObject:object];
}

+ (void)addGaiaObserver:(id<GAIAEngineObserver>)observer {
    pthread_mutex_lock(&_observerLock);
    [[[self sharedInstance] observers] addObject:observer];
    pthread_mutex_unlock(&_observerLock);
}

+ (void)removeGaiaObserver:(id<GAIAEngineObserver>)observer {
    pthread_mutex_lock(&_observerLock);
    [[[self sharedInstance] observers] removeObject:observer];
    pthread_mutex_unlock(&_observerLock);
}

- (void)_notifyObserverTasksWillStartForKey:(NSString *)key {
    pthread_mutex_lock(&_observerLock);
    for (id<GAIAEngineObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(gaiaTasksWillStartForKey:)]) {
            [observer gaiaTasksWillStartForKey:key];
        }
    }
    pthread_mutex_unlock(&_observerLock);
}

- (void)_notifyObserverTasksDidStartForKey:(NSString *)key {
    pthread_mutex_lock(&_observerLock);
    for (id<GAIAEngineObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(gaiaTasksDidStartForKey:)]) {
            [observer gaiaTasksDidStartForKey:key];
        }
    }
    pthread_mutex_unlock(&_observerLock);
}

- (void)_notifyObserverTaskWillExecute:(__kindof GAIATask *)task forKey:(NSString *)key {
    pthread_mutex_lock(&_observerLock);
    for (id<GAIAEngineObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(gaiaTaskWillExecute:forKey:)]) {
            [observer gaiaTaskWillExecute:task forKey:key];
        }
    }
    pthread_mutex_unlock(&_observerLock);
}

- (void)_notifyObserverTaskDidExecute:(__kindof GAIATask *)task forKey:(NSString *)key {
    pthread_mutex_lock(&_observerLock);
    for (id<GAIAEngineObserver> observer in self.observers) {
        if ([observer respondsToSelector:@selector(gaiaTaskDidExecute:forKey:)]) {
            [observer gaiaTaskDidExecute:task forKey:key];
        }
    }
    pthread_mutex_unlock(&_observerLock);
}


- (void)startTasksForKey:(NSString *)key {
    [self _notifyObserverTasksWillStartForKey:key];
    pthread_mutex_lock(&_lock);
    if (!gaia_tasks) {
        pthread_mutex_unlock(&_lock);
        return;
    }
    NSMutableArray *taskArray = gaia_tasks[key].mutableCopy;
    pthread_mutex_unlock(&_lock);
    if (!taskArray) {
        return;
    }
    [taskArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(GAIATask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self _notifyObserverTaskWillExecute:obj forKey:key];
        [obj start];
        [self _notifyObserverTaskDidExecute:obj forKey:key];
        if (!obj.repeatable) {
            [taskArray removeObject:obj];
        }
    }];

    pthread_mutex_lock(&_lock);
    if (taskArray.count == 0) {
        [gaia_tasks removeObjectForKey:key];
        if (gaia_tasks.count == 0) {
            gaia_tasks = nil;
        }
    }
    else {
        [gaia_tasks setObject:taskArray forKey:key];
    }
    pthread_mutex_unlock(&_lock);
    [self _notifyObserverTasksDidStartForKey:key];
}

- (void)startTasksForKey:(NSString *)key withObject:(id)object {
    [self _notifyObserverTasksWillStartForKey:key];
    pthread_mutex_lock(&_lock);
    if (!gaia_tasks) {
        pthread_mutex_unlock(&_lock);
        return;
    }
    NSMutableArray *taskArray = gaia_tasks[key].mutableCopy;
    pthread_mutex_unlock(&_lock);
    if (!taskArray) {
        return;
    }
    [taskArray enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(GAIATask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self _notifyObserverTaskWillExecute:obj forKey:key];
        [obj startWithObject:object];
        [self _notifyObserverTaskDidExecute:obj forKey:key];
        if (!obj.repeatable) {
            [taskArray removeObject:obj];
        }
    }];
    
    pthread_mutex_lock(&_lock);
    if (taskArray.count == 0) {
        [gaia_tasks removeObjectForKey:key];
    }
    else {
        [gaia_tasks setObject:taskArray forKey:key];
    }
    pthread_mutex_unlock(&_lock);
    [self _notifyObserverTasksDidStartForKey:key];
}

- (NSHashTable *)observers {
    if (!_observers) {
        _observers = [NSHashTable weakObjectsHashTable];
    }
    return _observers;
}



@end

