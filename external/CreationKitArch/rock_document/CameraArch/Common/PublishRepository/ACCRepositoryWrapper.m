//
//  ACCRepositoryWrapper.m
//  CreationKitArch-Pods-Aweme
//
//  Created by liyingpeng on 2021/4/22.
//

#import "ACCRepositoryWrapper.h"
#import "NSMutableDictionary+RepositoryContainer.h"
#import <objc/runtime.h>
#import <CreativeKit/ACCMacros.h>
#import "AWEVideoPublishViewModel.h"

@interface ACCRepositoryRegisterInfo ()

@property (nonatomic, weak, readwrite, nullable) ACCRepositoryRegisterInfo *childNode;
@property (nonatomic, weak, readwrite, nullable) ACCRepositoryRegisterInfo *superNode;

@end

@implementation ACCRepositoryRegisterInfo

- (instancetype)initWithClassInfo:(Class)classInfo
{
    self = [super init];
    if (self) {
        _classInfo = classInfo;
        _initialWhenSetup = YES;
    }
    return self;
}

- (instancetype)init
{
    return [self initWithClassInfo:nil];
}

@end

@interface ACCRepositoryWrapper ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *registerNodeInfoHash;

@end

@implementation ACCRepositoryWrapper
@synthesize extensionModels = _extensionModels;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _registerNodeInfoHash = @{}.mutableCopy;
    }
    return self;
}

- (NSMutableDictionary *)extensionModels
{
    @synchronized (self) {
        if (!_extensionModels) {
            _extensionModels = [NSMutableDictionary new];
        }
        return _extensionModels;
    }
}

- (void)setExtensionModels:(NSMutableDictionary *)extensionModels
{
    [extensionModels enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([NSClassFromString(key) conformsToProtocol:@protocol(ACCRepositoryContextProtocol)]) {
            [(id<ACCRepositoryContextProtocol>)obj setRepository:self];
        }
    }];
    
    @synchronized (self) {
        _extensionModels = extensionModels;
    }
}

- (NSDictionary *)registerNodeInfo {
    return self.registerNodeInfoHash.copy;
}

- (void)insertRegisterInfo:(ACCRepositoryRegisterInfo *)registerInfo {
    Class classInfo = registerInfo.classInfo;
    // If the parent class object is inserted, some properties of the child class object may be lost, which is not allowed at present.
    if ([self.registerNodeInfoHash objectForKey:NSStringFromClass(classInfo)]) {
        ACCRepositoryRegisterInfo *info = (ACCRepositoryRegisterInfo *)[self.registerNodeInfoHash objectForKey:NSStringFromClass(classInfo)];
        if (info.childNode) {
            NSAssert(NO, @"you should not insert instance which has sub class instance");
        }
    }
    [self.registerNodeInfoHash setObject:registerInfo forKey:NSStringFromClass(classInfo)];
}

- (void)setupRegisteredRepositoryElements {
    SEL sel = @selector(repoRegisterInfo);
    [AWEVideoPublishViewModel enumerateImplementationOfSelector:sel UsingBlock:^(IMP imp, BOOL *stop) {
        // invoke extensionModelForRepositoryWhenSetup
        ACCRepositoryRegisterInfo *registerInfo = ((id(*)(id, SEL))imp)(self, sel);
        Class classInfo = registerInfo.classInfo;
        Class superClass = class_getSuperclass(classInfo);
        // Constructing inheritance chain
        if (![NSStringFromClass(superClass) isEqualToString:@"NSObject"]) {
            ACCRepositoryRegisterInfo *superNode = (ACCRepositoryRegisterInfo *)[self.registerNodeInfoHash objectForKey:NSStringFromClass(superClass)];
            if (superNode) {
                superNode.childNode = registerInfo;
                registerInfo.superNode = superNode;
            } else {
                // Using subclass to occupy space
                [self.registerNodeInfoHash setObject:registerInfo forKey:NSStringFromClass(superClass)];
            }
        }
        // Adjust subclass pointer
        if ([self.registerNodeInfoHash objectForKey:NSStringFromClass(classInfo)]) {
            ACCRepositoryRegisterInfo *childNode = (ACCRepositoryRegisterInfo *)[self.registerNodeInfoHash objectForKey:NSStringFromClass(classInfo)];
            if (![NSStringFromClass(childNode.classInfo) isEqualToString:NSStringFromClass(registerInfo.classInfo)]) {
                registerInfo.childNode = childNode;
                childNode.superNode = registerInfo;
            }
        }
        [self.registerNodeInfoHash setObject:registerInfo forKey:NSStringFromClass(classInfo)];
    }];
}

#pragma mark - ACCPublishRepository api

- (BOOL)setExtensionModelByClass:(id)extensionModel
{
    if ([extensionModel conformsToProtocol:@protocol(ACCRepositoryContextProtocol)]) {
        [(id<ACCRepositoryContextProtocol>)extensionModel setRepository:self];
    }
    if (![self.registerNodeInfoHash objectForKey:NSStringFromClass(object_getClass(extensionModel))]) {
        ACCRepositoryRegisterInfo *registerInfo = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:object_getClass(extensionModel)];
        [self insertRegisterInfo:registerInfo];
    }
    return [self.extensionModels acc_setExtensionModelByClass:extensionModel];
}

- (void)removeExtensionModel:(Class)modelClass
{
    [self.extensionModels acc_removeExtensionModel:modelClass];
}

- (id)extensionModelOfClass:(Class)modelClass
{
    ACCRepositoryRegisterInfo *registerInfo = (ACCRepositoryRegisterInfo *)[self.registerNodeInfoHash objectForKey:NSStringFromClass(modelClass)];
    while (registerInfo.childNode) {
        registerInfo = registerInfo.childNode;
    }
    return [self.extensionModels acc_extensionModelOfClass:registerInfo.classInfo];
}

- (id)extensionModelOfProtocol:(Protocol *)protocol
{
    id result = [self.extensionModels acc_extensionModelOfProtocol:protocol];
    return result;
}

- (NSMutableDictionary *)deepCopyExtensionModels
{
    return [self.extensionModels acc_deepCopyExtensionModels];
}

- (void)enumerateExtensionModels:(BOOL)needCopy requireProtocol:(Protocol *)protocol requireSelector:(SEL)sel block:(void (^)(NSString *, id, BOOL *))block
{
    [self.extensionModels acc_enumerateExtensionModels:needCopy requireProtocol:protocol requireSelector:sel block:block];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    ACCRepositoryWrapper *wrapper = [[[self class] alloc] init];
    wrapper.registerNodeInfoHash = self.registerNodeInfoHash.mutableCopy;
    return wrapper;
}

@end
