//
//  IESComposerModel.h
//  Pods
//
//  Created by stanshen on 2018/9/29.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

typedef NS_ENUM(NSInteger, IESComposerNodeType) {
    IESComposerNodeTypeClear = -1, // 清除项，点击清除当前选中特效
    IESComposerNodeTypeItem = 0, // 叶子节点，点击生效
    IESComposerNodeTypeCategory = 1, //组合项，有子节点，且互斥
    IESComposerNodeTypeBiSlider = 2, // 叶子结点，点击出现双向滑动杆
    IESComposerNodeTypeSiSlider = 3, // 叶子节点，点击出现单向滑动杆
    IESComposerNodeTypeGroup = 4 // 组合项，有子节点，且不互斥
};

@interface IESComposerNode : MTLModel

@property (nonatomic, assign) IESComposerNodeType type; // 节点类型
@property (nonatomic, strong) NSString *uiName; // 节点UI名字
@property (nonatomic, strong) NSString *iconUri; // 节点Icon地址
@property (nonatomic, strong) NSString *tagName; // 节点TAG，后面可能用于参数Key，用于对特效进行指定参数调节
@property (nonatomic, assign) float defaultValue; // 节点默认值，节点类型是slider时有用
@property (nonatomic, assign) float maxValue; // 节点最大值，节点类型是slider时有用
@property (nonatomic, assign) float minValue; // 节点最小值，节点类型是slider时有用
@property (nonatomic, strong) NSString *fileUri; // 节点特效zip地址，当节点类型是叶子结点时有用
@property (nonatomic, strong) NSString *leafNodeId; // 叶子特效节点id，当节点类型是叶子结点时有用
@property (nonatomic, strong) NSArray<IESComposerNode *>* children; // 子节点数组，当节点类型是组合项时有用

// 以下不是从文件解析生成，而是为了使用方便而添加的变量或函数
@property (nonatomic, weak) IESComposerNode *parent; // 父节点，方便回到上一层
@property (nonatomic, assign) BOOL selected; // 当前节点是否处于选中状态
@property (nonatomic, strong) NSString *fileLocalPath; // 当前节点的特效资源包本地路径，当节点类型是叶子结点时有用，需要业务方下载资源包后进行设置
+ (id)nodeWithType:(IESComposerNodeType)type; // 根据type构造一个节点

@end

@interface IESComposerModel : MTLModel

@property (nonatomic, strong) NSString *tag;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSArray *requirement;
@property (nonatomic, strong) IESComposerNode *virtualRoot; // （虚拟）根节点，通过该节点可以遍历整棵树形结构

// 以下不是从文件解析生成，而是为了使用方便添加的变量或函数
@property (nonatomic, strong) IESComposerNode *currentNode; // 当前选中节点，通过该节点可以知道当前处在树的什么位置，便于进入下一层或返回上一层
@property (nonatomic, strong) NSString *resourceDir; // composer资源包的本地路径根目录
- (id)initWithPath:(NSString *)path; // 根据composer特效资源包文件进行解析
- (NSArray<IESComposerNode *> *)allLeafNodes; // 所有的特效叶子结点，可以直接获取当前composer下的所有叶子特效
- (NSArray<NSString *> *)allSelectedLeafNodePaths; // 所有选中的特效叶子节点的本地路径，可以直接调用去获取当前composer下选中的叶子特效

@end





