//
//  BDPCascadeStyleManager.m
//  Timor
//
//  Created by 刘相鑫 on 2019/10/11.
//

#import "BDPCascadeStyleManager.h"
#import "BDPCascadeStyleNode.h"

#define LOCK (dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER))
#define UNLOCK (dispatch_semaphore_signal(self.semaphore))

@interface BDPCascadeStyleManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, BDPCascadeStyleNode *> *clsNodeMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *, BDPCascadeStyleNode *> *nodeTrees;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation BDPCascadeStyleManager

#pragma mark - Init

+ (instancetype)sharedManager
{
    static BDPCascadeStyleManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [BDPCascadeStyleManager new];
    });
    
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - Style

- (void)applyStyleForObject:(NSObject *)obj category:(NSString *)category
{
    BDPCascadeStyleNode *node = [self styleNodeForClass:obj.class category:category aotuCreate:NO];
    if (!node) {
        return;
    }
    
    BDPCascadeStyleNode *rootNode = [self rootNodeForCategory:category];
    
    NSMutableArray<BDPCascadeStyleNode *> *cascadeNodes = [NSMutableArray array];
    // 串起一个反向链表
    BDPCascadeStyleNode *cNode = node;
    while (cNode != rootNode && cNode) {
        [cascadeNodes addObject:cNode];
        cNode = cNode.parentNode;
    }
    // 从最高层开始级联应用style
    [cascadeNodes enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(BDPCascadeStyleNode * _Nonnull node, NSUInteger idx, BOOL * _Nonnull stop) {
        [node applyStyleForObject:obj];
    }];
}

#pragma mark - Node Manage

- (BDPCascadeStyleNode *)styleNodeForClass:(Class)cls
                                  category:(NSString *)category
{
    return [self styleNodeForClass:cls category:category aotuCreate:YES];
}

- (BDPCascadeStyleNode *)styleNodeForClass:(Class)cls
                                  category:(NSString *)category
                                aotuCreate:(BOOL)autoCreate
{
    NSString *key = [self keyForClass:cls category:category];
    
    BDPCascadeStyleNode *node = nil;
    if (key) {
        node = self.clsNodeMap[key];
    }
    if (!node && autoCreate) {
        node = [self nodeWithClass:cls category:category];
    }
    
    return node;
}

- (BDPCascadeStyleNode *)nodeWithClass:(Class)cls
                              category:(NSString *)category
{
    BDPCascadeStyleNode *node = [BDPCascadeStyleNode new];
    node.cls = cls;
    node.category = category;
    
    NSString *key = [self keyForClass:cls category:category];
//    LOCK;
    self.clsNodeMap[key] = node;
    
    // insert node to parent node tree
    BDPCascadeStyleNode *parentNode = [self parentNodeForNode:node];
    for (BDPCascadeStyleNode *childNode in parentNode.childNodes) {
        if ([childNode.cls isSubclassOfClass:node.cls]) {
            [node addChildNode:childNode];
        }
    }
    [parentNode addChildNode:node];
    
//    UNLOCK;
    return node;
}

- (BDPCascadeStyleNode *)parentNodeForNode:(BDPCascadeStyleNode *)node
{
    BDPCascadeStyleNode *parentNode = nil;
    BDPCascadeStyleNode *findedNode = [self rootNodeForCategory:node.category];
    while (parentNode != findedNode) {
        parentNode = findedNode;
        for (BDPCascadeStyleNode *childNode in parentNode.childNodes) {
            if ([node.cls isSubclassOfClass:childNode.cls]) {
                findedNode = childNode;
                break;
            }
        }
    }

    return findedNode;
}

- (NSString *)keyForClass:(Class)cls category:(NSString *)category
{
    if (!cls || !category) {
        return nil;
    }
    
    NSString *key = [NSString stringWithFormat:@"%@-%@", NSStringFromClass(cls), category];
    return key;
}

- (BDPCascadeStyleNode *)rootNodeForCategory:(NSString *)category
{
    if (!category) {
        return nil;
    }
    
    BDPCascadeStyleNode *rootNode = self.nodeTrees[category];
    if (!rootNode) {
//        LOCK;
        rootNode = [BDPCascadeStyleNode new];
        self.nodeTrees[category] = rootNode;
//        UNLOCK;
    }
    
    return rootNode;
}

#pragma mark - Getter && Setter

- (NSMutableDictionary<NSString *,BDPCascadeStyleNode *> *)clsNodeMap
{
    if (!_clsNodeMap) {
        _clsNodeMap = [NSMutableDictionary dictionary];
    }
    
    return _clsNodeMap;
}

- (NSMutableDictionary<NSString *,BDPCascadeStyleNode *> *)nodeTrees
{
    if (!_nodeTrees) {
        _nodeTrees = [NSMutableDictionary dictionary];
    }
    return _nodeTrees;
}

@end
