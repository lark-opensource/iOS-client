//
//  BDClientABManager.h
//  ABTest
//
//  Created by ZhangLeonardo on 16/1/19.
//  Copyright © 2016年 ZhangLeonardo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BDABTestBaseExperiment.h"

/**
 *  @Wiki: https://wiki.bytedance.net/pages/viewpage.action?pageId=52052914
 *
 *  为什么需要客户端AB测试框架:
 *  1.让业务逻辑开发RD可以不关心AB测试部分，不管是设计，还是编码与AB测试解耦。同时减少因为分组相关的代码出现错误的可能（非常容易）。提高效率，大幅度降低出现错误的可能。
 *  2.可以简化多个实验并存的情况的设计和编码，达到正交的实验可以互不相干，相干的实验最多只能出现一个。
 *  3.可以做到组合后的比例是固定的。
 *
 *  概念
 *
 *  Layer
 *  相干的实验，都应该在一个Layer中，正交的实验在不同layer中。
 *  一个完整的层必须包含如下信息：
 *
 *  layer name
 *  1.层的名字，用于唯一识别一个层， 不同层的layer name必须不能相同，包括历史版本。不同app 可以用同一个层的名字。
 *  2.层的定义都在文档：客户端AB测试框架 实验记录表中。
 *
 *  filters
 *  1.过滤条件，层需要有过滤条件， 为了简化设计，过滤条件放到了层的级别（另外一个方案是放到实验级别，如果有需要再扩展）
 *  2.过滤条件的定义见文档：客户端AB测试框架 filter key 定义表
 *
 *  experiments
 *  一个层中应该至少有一个实验组、有且仅有一个默认组。eg:
 *  实验组1
 *  实验组2   //可选
 *  实验组3   //可选
 *  ...            //可选
 *  实验组n  //可选
 *  默认组
 *  一个实验应该包括如下信息：
 *
 *  group name
 *  实验命中后的分组名，这个名字作为实验的唯一标识。
 *
 *  min region
 *  该实验取值区间的左区间， 一个层会被分成1000分，这样理论上一个层中可以同时进行1000个实验。
 *
 *  max region
 *  该实验取值区间的右区间
 *
 *  results
 *  实验命中之后，需要修改的feature key 和对应的value 的集合
 *
 *  随机数R
 *  每一个Layer，都需要有一个，且仅只有一个随机数(0-999，共划分1000份)，没有的时候需要生成。随机数需要持久化存储，保证应用没有卸载过的情况下(Android的存储没有被系统清除的情况下)同一个层的随机数不变。
 *
 *  traffic_map
 *  描述层及实验信息的json文件(ab.json),具体定义见文档：客户端AB测试框架 ab.json文件说明
 *
 *  API通用参数说明：
 *  1.ab_feature
 *  反应当前应用的状态。以后不由业务层管理， 由ABManager管理，ABManager根据ab.json中的filters_key,来决定当前版本有哪些值需要发送， ab.json的定义见客户端AB测试框架 JSON文件说明
 *  2.ab_group
 *  每个版本计算完分组之后（计算且仅计算一次）， 就不会再变了。
 *  3.ab_version
 *  服务端下发的信息， 客户端透传给服务端, 此功能是用于服务端修改了客户端的分组信息后， 告诉统计，对应的用户应该从实验组中去除。
 *  实验
 *
 *  设计实验
 *  假设设计如下实验：
 *  测试“清除缓存”和“清理缓存”对用户的影响，那么需要进行如下：
 *  1.明确所在layer（层）
 *  2.明确分组内的所有实验， 及每个实验的取值范围和标记
 *  3.明确所在layer（层）
 *  4.那么，首先需要明确该实验所在的层。因为还没有开始过任何实验， 暂时没有层，所以新建一个层，取名 ：first_blood
 *
 *  明确分组内的所有实验， 及每个实验的取值范围和标记
 *  实验组 和默认组：
 *  ----------------------------------------------
 *  |   分组      |   逻辑      |   标记  |   流量  |
 *  |--------------------------------------------|
 *  |   实验组1   |    清除缓存  |   z1   |   30%   |
 *  |--------------------------------------------|
 *  |   实验组2   |    清理缓存  |   z2   |   30%  |
 *  |--------------------------------------------|
 *  |   默认组    |    清除缓存  |   无    |  40%   |
 *  |--------------------------------------------|
 *  对上表可以进行如下理解：
 *  1.实验组1取值区间为0-299，如果命中， 该实验对应的group name为z1
 *  2.实验组2取值区间为300-599，如果命中， 该实验对应的group name为z2
 *  3.实验组3取值区间为600-999，命中默认组，没有group name.
 *
 *  进行实验
 *  设计完实验后， 开始进行实验
 *  首先看该版本是否进行过实验， 如果已经进行过， 直接返回之前的实验结果。没有进行过执行后续操作
 *  拿到layer 对应的随机数， 如果没有， 分配一个随机数（0-999）。
 *  然后取随机数对应的实验。
 *  取到试验后， 执行实验（写入results)。
 *  然后取实验对应的group name。
 *  所有实验进行完后， 将所有的group name ，用“,”分隔 ，拼接成字符串，构建成ABGroups。实验进行完毕。
 *
 *  具体操作流程如下：
 *  1.该版本第一次启动， 发现该版本没有进行过实验， 则开始实验逻辑
 *  2.首先解析ab.json文件，将ab.json文件翻译成对应的layer对象。
 *  3.此时发现，此版本只有一个layer：first_blood,
 *  4.去存储区（）中查看下， 是否已经分配过随机数，发现还没有， 生成一个随机数，假设是199.
 *  5.此时去实验表中看，199 对应哪个实验， 发现是实验1
 *  6.执行实验1的实验。将result 对应的key vlaue写入存储区
 *  7.然后取实验1对应的group name：z1
 *  8.因为此版本就只有一个实验， 所以此版本此时的ab_group 和 ab_feature都是z1
 *  9.服务器线上修改实验
 *  10.客户端AB测试框架允许服务端在线修改实验feature。 但是修改完后，该用户的客户端实验将不在有效。具体操作如下:
 *  11.客户端通过settings 下发修改指令，能够修改的功能点都在文档 : 客户端AB测试框架 filter key 定义表 中定义（普通key）
 *  12.settings对应的修改可以为：ab_settings
 *  13.当服务端修改了ab_settings之后， 应该还需要修改ab_version。 如上面ab_version的定义， ab_version用来指导统计，该用户的功能已经被服务器修改了。
 *  14.客户端功能被服务端修改后， ab_feature要跟着当前状态改变， ab_group每个版本确定后， 就不再变化了。
 *
 *  实现方案
 *  输入：
 *  ab.json (包含：layer信息，需要发送feature key)
 *  输出：
 *  ab_group/ab_feature
 *
 *  客户端需要实现处理类逻辑
 *  处理类要记住每个Layer的随机数。
 *  输出即为结果， 如果某一个层没有输出， 使用默认值。
 *  该设计和 上一个版本设计的区别是
 *  该设计是白名单， 产品需要想清楚都要测试哪些后，再添加。
 *  以前的设计是黑名单，产品明确哪些不需要，把不需要的去掉。
 *  目前设计的一个局限性是：
 *  AB测试和版本强依赖， 想上一个新的AB测试， 必须通过发版。
 */
@interface BDClientABManager : NSObject

+ (instancetype)sharedManager;

/**
 客户端本地分流实验使用，注册一个本地实验层，重复注册则仅第一次才会成功
 支持多线程调用
 
 @return 注册成功与否结果，重复注册则仅第一次才会成功
 */
- (BOOL)registerClientLayer:(BDClientABTestLayer *)clientLayer;

/**
 客户端本地分流实验使用，根据层名称获取本地实验层
 支持多线程调用
 
 @return 客户端本地分流实验层，如果不存在、不会创建
 */
- (BDClientABTestLayer *)clientLayerByName:(NSString *)name;

/**
 *  初始化方法，确保客户端本地分流实验都注册后，才能调用此方法
 */
- (void)launchClientExperimentManager;

/**
 *  保存服务器下发的修改，客户端本地分流实验值可以通过此接口被服务端修改，以解决patch问题
 *
 *  @param dict 服务器下发的修改的集合(featurekey:value)
 */
- (void)saveServerSettingsForClientExperiments:(NSDictionary *)dict;

/**
 *  返回指定featureKey对应的值
 *
 *  @param featureKey 指定的featureKey
 *
 *  @return 指定featureKey key对应的值
 */
- (id)valueForFeatureKey:(NSString *)featureKey;

#pragma mark others

/**
 *  返回指定featureKey对应的服务端下发的替换本地的setting中的feature值
 *
 *  @param featureKey 指定的featureKey
 *
 *  @return 指定featureKey key对应的值
 */
- (id)serverSettingValueForFeatureKey:(NSString *)featureKey;

/**
 *  返回指定Layer对应的vid
 *
 *  @param layerName 指定的Layer名称
 *
 *  @return vid 对应的vid
 */
- (NSNumber *)vidForLayerName:(NSString *)layerName;

/**
 *  返回当前客户端本地分流实验vid列表
 *
 *  @return vidList 对应的vid列表
 */
- (NSArray *)vidList;

/**
 *  返回当前客户端本地分流实验命中的所有组的vid拼接成的字符串
 *
 *  @return ABGroup 客户端本地分流实验命中的所有组的vid拼接成的字符串
 */
- (NSString *)ABGroup;

/**
 *  ab version
 *
 *  @return ab version
 */
- (NSString *)ABVersion;

/**
 *  设置ab version
 *
 *  @param abVersion abVersion
 */
- (void)saveABVersion:(NSString *)abVersion;

@end
