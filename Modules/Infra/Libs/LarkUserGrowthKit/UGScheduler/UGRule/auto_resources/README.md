## 说明文档

[UG SDK - Tech Design - 规则触发模块 - 飞书云文档](https://bytedance.feishu.cn/wiki/wikcn7d21Yfu3fELvGTLaW8gTSg)


# 名词解释

*   **触达点**: 业务侧的、UG 相关的消息传递点位，包括但不限于 banner、短信、推送、弹窗、红点
*   **规则:** 在管理后台为触达点规则，
    *   1**本地规则:** 为业务方配置的规则称之为本地规则，比如: input 为 abc 的时候，弹出一个引导气泡
    *   **组件规则:** 配置在 node 节点上规则称之为组件规则，比如: 互斥、抢占、优先级等规则是

# 业务背景

随着 UG 业务不断扩展，触达点位的数量、形式以及涉及的业务线越来越多，原先的业务推进方式的弊端也组件显露出来

*   业务零碎: 几乎各条业务线都有 UG 的业务
*   触达组件各自为政: 触达组件未进行通用的抽象，各搞各的，出现很多冗余的、重复的工作
*   UG 交互调整不灵活: 因为历史接入方式为硬编码，所以每次 UG 交互变更，都需要进行排期开发，而且涉及业务线太多，跨团队协作成本较高

所以团队决定设计开发一个 [UG 中台](https://bytedance.feishu.cn/wiki/wikcnOnYL2g6juYhCJ82ozxVKSd) 来降低新业务的设计、开发成本，PC 侧整体分层如下，本文主要介绍 SDK - 调度层中的「规则触发」模块

*   规则模块职责
    *   承担对配置规则的拉取&管理、解析&计算
    *   将引导展示/消费的结果通过消息总线给到调度模块

# 需求特征

*   可以允许用户/业务方为特定的业务场景配置特定的逻辑
*   可以感知到业务方的交互变动
*   可以通过输入的交互行为和规则，在特定的时间做出特定的行为(消息推送、发请求等等)

# 方案设计

![](https://bytedance.feishu.cn/space/api/box/stream/download/asynccode/?code=ZTczMmQ1OGI4YWE1MWEwNDhhMmNjMjMwNjY4MmZkMjJfd3BUYU9Kdkt2NGJmN1pmRzlFbTI0Q2ZranNPMjhlcWxfVG9rZW46Ym94Y25yY2dmbFJKVmd1eXJIaDdnUWd4cHBjXzE2MTU2MTk1NjA6MTYxNTYyMzE2MF9WNA)

规则模块整体属于「调度模块」内，包含"计算"、"规则解析". 调度模块内通过EventBus(移动端上是个消息监听中心)将规则的拉取、计算结果的事件进行同步。

*   调度模块初始化时，统一接入层会通过EventBus让规则触发拉取本地规则
*   然后这些本地规则通过规则解析转换成表达式，存入内存
*   当EventBus收到接入层的注册/消费事件时，将Scene对应的LocalRule进行匹配，如果匹配到，则获取对应的表达式进行计算，获取计算结果
*   将计算结果通过EventBus返回给监听的冲突协调/接入层

## 功能目标

根据需求特征以及整体设计，「规则触发模块」的整体设计如下：

 不支持在 Docs 外粘贴 block 

1.  规则计算模块只需要感知元规则，即**可以描述规则的规则**。这些**元规则**理论上是可以被完全枚举的。
2.  **规则解析模块负责将外部输入的具有业务语义的各种规则进行转义**，**转换成元规则**。供规则计算模块消费。
3.  规则解析模块支持**业务自定义**。

## 模块职责详解

「规则触发」各模块具体介绍如下：

#### 规则解析

*   数据模块将 bytes 解析为 json (移动端是对象)之后，流入调度模块，然后「规则解析」模块将「本地规则数据」转化为规则表达式，交由「规则计算模块」计算，或者传入冲突协调模块立即更新 node 关系
*   将具体的业务action 转移成元规则，供规则引擎消费。
*   提供业务注册自定义action 到元规则转换能力的接口。
*   消息来源为「规则解析」、EventBus 两块
*   「规则解析」流入的数据来自管理后台，通常用来控制组件的业务规则，比如：按钮点击 5 次弹出气泡、输入框输入 abc 弹出气泡等等。输出规则计算模块能够识别的元规则数据。
*   EventBus 流入的消息来自业务方，该消息即规则表达式条件，比如：click 动作、input 内容

#### 规则计算

进行规则计算或者追踪计算。

*   元规则类型可枚举，规则计算模块对所有的元规则可完备计算。
    *   ~~例如：下发规则「Banner~~~~点击~~~~x次弹出气泡」和「Banner~~~~延时~~~~x秒展示」，这些就是对应规则类型，算法需要在SDK内编写好；~~

## 功能抽象落地

#### 通用规则能力

可以支持业务方注册自定义的、可以进行逻辑运算的规则，计算模块会在规则满足的时候执行相应的动作

*   注册接口: 由 modal 模块层提供新增自定义规则的 CRUD 接口，调度模块的数据来源有且仅有数据模块

![](https://bytedance.feishu.cn/space/api/box/stream/download/asynccode/?code=YTllMmU2OTVmZjFjNzI3ZTBiMWViYjI0NTNhZWViYjhfcENhemk1UFNoMDFXYUk0UnJLM05zSFEzeUJkREltYXhfVG9rZW46Ym94Y25oRENOU1ZUOWZ4MmNMY0pIOFdGeEFiXzE2MTU2MTk1NjA6MTYxNTYyMzE2MF9WNA)

*   本地通用规则的数据会并入「本地规则」一起流入「规则触发」模块，预期功能形态如下：
    *   打点规则: 触发某个条件，进行打点上报（上报动作可以走 SDK 默认的也可以自己传入 func）
        *   可以抽离通用的日志/埋点模块，这里只是规则触发，不做真正的打点动作
    *   追踪规则: 接受线性的若干条件，条件满足之后进行打点上报、计算结果回传等等
    *   ... extending

## 数据状态管理

*   规则中心数据来源有且仅有存储模块，如果出现程序意外终止，造成运行时数据丢失，视为正常情况
*   对于累计点击场景，每次点击都应该通知数据模块更新数据(本地数据+远端数据)
*   尽量不做有副作用的操作

## 数据结构&接口

我们关心的规则，分为三类：

*   SDK 初始化批量拉取的前置规则
*   和触达组件成对下发的本地规则
*   业务方注册的规则

PB 结构如下：

[Tech Design - UG SDK 网络通信方案](https://bytedance.feishu.cn/docs/doccnb0e61riEjNnMLMwwRcQ44f#)

```
message LocalRule {
  string scene_id = 1;
  string rule_id = 1;
  RuleExpression root_exp_node = 2;  // 表达式二叉树的根节点
  bool need_replay = 3; // 是否支持重放
  string trigger_event_name = 4;  // <后续扩展>当触达条件被满足时触发的内置方法, 用于上报回调事件，不过可以考虑直接使用Scene_id
}

// 本地触达规则信息
message RuleExpression {
  enum ConditionOperator {
    UNKNOWN_CONDITION = 0;
    AND = 1;
    OR = 2;
    NOT = 3;
  }

  enum ExpressionOperator {
    UNKNOWN_EXPRESSION = 0;
    IN = 1;
    EQUAL = 2;
    NOT_EQUAL = 3;
    LESS_OR_EQUAL = 4;
    LESS_THAN = 5;
    GREATER_OR_EQUAL = 6;
    GREATER_THAN = 7;
  }

  RuleExpression left = 1;
  RuleExpression right = 2;
  string ruleAction = 3; // 下发的规则Action,规则触发事件, 解析成元规则/ 自定义规则
  string value = 4; // 阈值
  ExpressionOperator exp_operator = 5;  // 条件表达式内的逻辑运算符
  ConditionOperator cond_operator = 6;  // 条件表达式间的逻辑运算符
}

message ScenarioContext{
  string scenario_id = 1;
  LocalRule local_rule = 2;  // 业务场景触发的本地触达规则(满足才曝光触达)
  int32 priorities = 3;
  repeated string share_scenario_ids = 4;
  repeated UGReachPointEntity entities = 5;
}

```

### 规则解析

```
// 元规则
enum MetaRule {
  COUNT = 0,    // 次数规则
  DURATION,     // 计时规则，触达展示的总时间Duration, 单位毫秒
  CONTENT,      // 内容规则
}

// 引导事件, 这块每个case可以关联对应的value
enum RuleAction {
  // 点击次数  
  CLICK_COUNT = "click_count", // Int
  // 展示次数
  SHOW_COUNT = "show_count", // Int
  // 展示时间
  SHOW_TIME = "show_time", // Int
  // input?
  INPUT = "input" // String
  // 焦点切换（暂无，一期不支持）
  BLUR = "blur"
}

// 表达式操作符
enum ExpressionOperator {
  In = 'in',    // 针对字符串比较场景使用
  LessThan = '<',  // 仅用于数字比较
  LessEqual = '<=', // 仅用于数字比较
  Equal = '==',
  NotEqual = '!=',
  GreaterEqual = '>=', // 仅用于数字比较
  Greater = '>', // 仅用于数字比较
  Regex = String, // 正则表达式，一期暂不支持
}
// 条件操作符
enum ConditionOperator {
  AND = '&&',
  OR = '||',
  NOT = '!',
}

type SimpleExp = number | string | boolean | object 
type Action = RuleAction

interface RuleActionData {
  type: ruleAction,
  value: number | string | boolean
}

interface BizRule { // 业务侧是规则
  action: Action
  thresholdVal?: string | boolean | number,
  tmpVal?: string | boolean | number,
}

type Operator = ExpressionOperator | ConditionOperator

type EventName = string;

// 表达式定义
interface Expression {
  id: string, // 唯一标记规则
  left?: Expression | SimpleExp,
  right?: Expression | SimpleExp,
  ruleAction?: RuleActionData
  expOperator: ExpressionOperator,
  conditOperator: ConditionOperator,  
  cb: () => any | EventName
}

type ReachPointRuleDataMap = Map<string, Expression> // r_id 和expression的map

type DeRegister = () => void

interface RuleParser { // 规则解析模块
  parserMap: Map<Action, (action: Action) => MetaRuleData>;
  registerParser: <T extends Action>(c_id: string, action: T, cb: () =>MetaRuleData ) => DeRegister;
  parseAction: (action: Action) => MetaRuleData;
}

interface RuleCalculate { // 规则计算模块
  expressionMap: Map<string, Expression>; // 存储表达式
  calExpression: (r_id: string) => boolean; // 计算表达式
}

interface RuleManager { // 规则触发模块
  initLocalRule: () => void; // 处理本地规则，解析为Expression 存储到 RuleCalculate.expressionMap
  updateRule: (r_id, rule: BizRule) => void; // 更新元规则数据
  getRuleResult: (r_id: string) => void;  
}

```

举例🌰：

下发一个本地规则： 点击触发4次，或 超过100s展示

*   CLICK >= 4 || SHOW_TIME >= 100000

```
// 1\. 收到总线的事件，获取对应的localRule
// 2\. 将localRule的rule字符串解析成MetaRule,并生成Expresson。
// 3\. 组装解析后的data, 形成LocalRule结构

// 转换后的复杂表达式
LocalRuleInfo {
    String: sid_id
    String: rule_id
    Expression： {
        // 外层条件
        ConditionOperator: "||",
        left: Expression {
            metaRule: {
               type: MetaRule.COUNT
               initialVal: 1,
               thresholdVal: 4            
            }
            // 内部计算
            ExpressionOperator: "==",
         }
         right: Expression {
              metaRule: {
               type: MetaRule.TIME
               initialVal: 0,
               thresholdVal: 1024            
            }
              // 内部计算
              ExpressionOperator: "=="
         }
     }
}
// 简单单层表达式
LocalRuleInfo {
    String: sid_id
    String: rule_id
    Expression： {
        // 外层条件
        metaRule: {
               type: MetaRule.CONTENT
               initialVal: "",
               thresholdVal: "hello"            
            }
        ExpressionOperator: "=="       
     }
}

interface Expression  {
  id: string, // 唯一标记规则
  value: SimpleExp //
  left: Expression？,
  right: Expression？,
  action: RuleAction?
  operator: Operator,
}

```

## 接口

目前移动端接口定义如下：

*   RuleManager：对外接口，管理内部逻辑

```
// 本地规则处理结果
message ReachPointDisplayInfo {
    string scenario_id = 1;  // 提供给调度
    string reach_point_id = 2;
    RuleAction action = 3;
    // 是否展示/消失消费，如果为空，表示不处理
    optional Bool? display = 4;
}

// 规则触发事件 iOS
struct RuleEvent {
    // 场景Id
    let scenarioID: String
    // 事件
    let action: RuleAction
    // 管理值
    let actionValue: String | Int
}

// Android
class RuleEvent(val scenarioId: String,
                       val actionEvent: String,
                       var extraInfo: Map<String, String>? = null) 

// 处理事件消息, rules: 外部注入规则数据，triggerEvent: 规则触发事件 RuleEvent
// 返回本地规则处理结果信号
func handleRuleEvent(rules: [LocalRuleInfo], triggerEvent: RuleEvent) -> Observable([ReachPointDisplayInfo]) {
    // 调用Cache的getComponentInfoById，更新本地规则（计数）
    // 获取表达式树的action
    // 更新规则的extraInfo
    // 调用RuleCaculator计算，组装ScenarioDisplayInfo
}

/// 自定义规则注册- 根据场景id 注册触达点位展示情况 
func registerMetaRuleParser(scenarioId: String, event: String, metaRule: MetaRule)

func unregisterMetaRuleParser(scenarioId: String, event: String)

```

*   RuleCaculator：解析、计算规则

```

// 通过rule的action,生成表达式列表
func generateExpressionsByRule(rule: LocalRule) -> [Expression]?

// 单次查询某个cid是否展示，执行localRules
func caculateRules(rid: String) -> Bool? {
    // 查询Component的rules
    // isDisplay =  er1 && er2 && er3 ...
}

```

事件重置：目前事件触发的currentValue存于内存memory，生命周期和模块一致， 如果涉及到本地持久化，需要考虑重置条件
