//
//  IESComposerModel.m
//  Pods
//
//  Created by stanshen on 2018/9/29.
//

#import "IESComposerModel.h"
#import "EffectPlatform.h"

@implementation IESComposerNode
+ (id)nodeWithType:(IESComposerNodeType)type {
    IESComposerNode *node = [IESComposerNode new];
    node.type = type;
    return node;
}
@end

@interface IESComposerModel()
@property (nonatomic, strong) NSMutableArray<IESComposerNode *> *leafNodes; // 所有叶子特效节点数组
@end
@implementation IESComposerModel
- (id)initWithPath:(NSString *)path {
    self = [super init];
    if (!self || !path) {
        return nil;
    }
    
    id dict = [self parseDictFromJsonFile:[path stringByAppendingString:@"/config.json"]];
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSDictionary *config = dict;
    NSArray *link = config[@"effect"][@"Link"];
    if (!link) {
        return nil;
    }
    
    self.resourceDir = path;
    for (NSDictionary *linkItem in link) {
        if ([linkItem[@"type"] isEqualToString:@"Composer"]) {
            NSString *composerPath = [path stringByAppendingFormat:@"/%@", linkItem[@"path"]];
            NSString *contentPath = [composerPath stringByAppendingString:@"content.json"];
            id contentDict = [self parseDictFromJsonFile:contentPath];
            if ([contentDict isKindOfClass:[NSDictionary class]]) {
                
                self.tag = contentDict[@"tag"];
                self.version = contentDict[@"version"];
                IESComposerNodeType type = (IESComposerNodeType)[contentDict[@"content"][@"type"] integerValue];
                self.virtualRoot = [IESComposerNode nodeWithType:type];
                self.leafNodes = @[].mutableCopy;
                NSMutableArray *children = @[].mutableCopy;
                if ([contentDict[@"content"][@"nodes"] isKindOfClass:[NSArray class]]) {
                    NSArray *nodes = contentDict[@"content"][@"nodes"];
                    for (NSDictionary *nodeDict in nodes) {
                        if (![self.class checkNodeExtraInfo:nodeDict[@"extra_info"]]) {
                            continue;
                        }
                        IESComposerNode *node = [IESComposerNode new];
                        node.parent = self.virtualRoot;
                        [self parseDict:nodeDict toComposerNode:node];
                        [children addObject:node];
                        if (node.type == IESComposerNodeTypeItem ||
                            node.type == IESComposerNodeTypeBiSlider ||
                            node.type == IESComposerNodeTypeSiSlider) {
                            [self.leafNodes addObject:node];
                        }
                    }
                }
                self.virtualRoot.children = children;
                self.currentNode = self.virtualRoot;
            }
        }
    }
    
    return self;
}

#pragma mark - parse dict fuctions

+ (BOOL)checkNodeExtraInfo:(NSDictionary *)extraInfo {
    if (extraInfo != nil) {
        NSString *sdkVersion = [EffectPlatform sharedInstance].effectVersion;
        NSString *minVersion = extraInfo[@"min_version"];
        if (minVersion != nil) {
            NSComparisonResult result = [minVersion compare:sdkVersion];
            if (result == NSOrderedDescending) { // 最小版本大于当前EffectSDK版本，则返回NO（过滤掉）
                return NO;
            }
        }
        NSString *version = extraInfo[@"version"];
        if (version != nil) {
            NSComparisonResult result = [version compare:sdkVersion];
            if (result == NSOrderedDescending) { // 叶子节点版本大于当前EffectSDK版本，则返回NO（过滤掉）
                return NO;
            }
        }
    }
    
    return YES;
}

- (id)parseDictFromJsonFile:(NSString *)jsonFile {
    NSString *jsonStr = [NSString stringWithContentsOfFile:jsonFile encoding:NSUTF8StringEncoding error:nil];
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    id object = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
    return object;
}

- (void)parseDict:(NSDictionary *)dict toComposerNode:(IESComposerNode *)composerNode {
    composerNode.iconUri = dict[@"icon"];
    composerNode.uiName = dict[@"UI_name"];
    IESComposerNodeType nodeType = (IESComposerNodeType)[dict[@"type"] integerValue];
    composerNode.type = nodeType;
    if (nodeType == IESComposerNodeTypeCategory ||
        nodeType == IESComposerNodeTypeGroup) {
        NSDictionary *nodes = dict[@"nodes"];
        NSMutableArray *children = @[].mutableCopy;
        for (NSDictionary *nodeDict in nodes) {
            if (![self.class checkNodeExtraInfo:nodeDict[@"extra_info"]]) {
                continue;
            }
            IESComposerNode *node = [IESComposerNode new];
            node.parent = composerNode;
            [self parseDict:nodeDict toComposerNode:node];
            [children addObject:node];
        }
        if (children.count > 0) {
            composerNode.children = children;
        }
    }
    else if (nodeType == IESComposerNodeTypeBiSlider ||
             nodeType == IESComposerNodeTypeSiSlider) {
        composerNode.defaultValue = [dict[@"default_value"] floatValue];
        composerNode.maxValue = [dict[@"max_value"] floatValue];
        composerNode.minValue = [dict[@"min_value"] floatValue];
        composerNode.fileUri = dict[@"file"];
        composerNode.tagName = dict[@"tag_name"];
        composerNode.leafNodeId = dict[@"id"]?:dict[@"file"];
        [self.leafNodes addObject:composerNode];
    }
    else if (nodeType == IESComposerNodeTypeItem) {
        composerNode.fileUri = dict[@"file"];
        composerNode.tagName = dict[@"tag_name"];
        composerNode.leafNodeId = dict[@"id"]?:dict[@"file"];
        [self.leafNodes addObject:composerNode];
    }
}

#pragma mark - fuctions
- (void)setCurrentNode:(IESComposerNode *)currentNode {
    BOOL clearAll = (currentNode.type == IESComposerNodeTypeClear);
    BOOL parentCategory = (currentNode.parent.type == IESComposerNodeTypeCategory);
    if (clearAll || parentCategory) { // 父节点是Category，子节点互斥
        for (IESComposerNode *node in currentNode.parent.children) {
            node.selected = NO;
        }
    }
    _currentNode = currentNode;
    if (!clearAll) {
        _currentNode.selected = YES;
    }
}

- (NSArray<NSString *> *)allSelectedLeafNodePaths {
    NSMutableArray *paths = @[].mutableCopy;
    for (IESComposerNode *node in self.leafNodes) {
        if (node.selected && node.fileLocalPath && ![paths containsObject:node.fileLocalPath]) {
            [paths addObject:node.fileLocalPath];
        }
    }
    return paths;
}

- (NSArray<IESComposerNode *> *)allLeafNodes {
    return self.leafNodes;
}


@end
