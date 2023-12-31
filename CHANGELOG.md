<a name="1.19.0-beta1"></a>
# 1.19.0-beta1 (2018-12-14)


### Bug Fixes

* fix memory leak of docsview, change calendar and ByteView version ([b913dac](https://review.byted.org/#/q/b913dac))
* **chat:** 解决会话气泡可能崩溃的问题 ([46f143f](https://review.byted.org/#/q/46f143f)), closes [#3499](https://jira.bytedance.com/browse/LKI-3499)
* LarkRustClient update to 1.3.1 ([975b921](https://review.byted.org/#/q/975b921))
* **account:** 多租户问题修复 ([a89f0a6](https://review.byted.org/#/q/a89f0a6)), closes [#3481](https://jira.bytedance.com/browse/LKI-3481)
* **chat:** 1.会话页面，在仍有未读消息的情况下，接着收到不可见消息，导致部分消息没有显示的问题 2.调整头尾插入数据检查 ([7e7d48c](https://review.byted.org/#/q/7e7d48c)), closes [#3489](https://jira.bytedance.com/browse/LKI-3489)
* **chat:** 修复feedback弹窗将chatvc弹起 ([a29a70a](https://review.byted.org/#/q/a29a70a)), closes [#3473](https://jira.bytedance.com/browse/LKI-3473)
* **chat:** 修复引导页UI不正确 ([777f710](https://review.byted.org/#/q/777f710)), closes [#3136](https://jira.bytedance.com/browse/LKI-3136)
* **chat:** 修复引导页不正确 ([9d04d1a](https://review.byted.org/#/q/9d04d1a)), closes [#3136](https://jira.bytedance.com/browse/LKI-3136)
* **chat:** 解决上拉加载更多新消息线可能丢失问题 ([67fdca5](https://review.byted.org/#/q/67fdca5)), closes [#3482](https://jira.bytedance.com/browse/LKI-3482)
* **component:** 修复log目录错误 ([cebdb65](https://review.byted.org/#/q/cebdb65)), closes [#3502](https://jira.bytedance.com/browse/LKI-3502)
* **contact:** 修复个人名片页申请按钮显示不正确 ([75904b9](https://review.byted.org/#/q/75904b9)), closes [#3510](https://jira.bytedance.com/browse/LKI-3510)
* **contact:** 群昵称/备注名featureGating替换 ([28d9dbf](https://review.byted.org/#/q/28d9dbf)), closes [#3475](https://jira.bytedance.com/browse/LKI-3475)
* **docs:** 文档页面点击更多可能出现无响应 ([643c2e6](https://review.byted.org/#/q/643c2e6))
* **feed:** 多租户切换时未注册和暂停用户提示不正确 ([701e9d1](https://review.byted.org/#/q/701e9d1)), closes [#3481](https://jira.bytedance.com/browse/LKI-3481)
* **login:** 修复 重新登录会死锁 ([3a6a28d](https://review.byted.org/#/q/3a6a28d)), closes [#3501](https://jira.bytedance.com/browse/LKI-3501)
* **message:** 修复上传 task manager 多线程问题 ([d828999](https://review.byted.org/#/q/d828999)), closes [#3490](https://jira.bytedance.com/browse/LKI-3490)
* **message:** 初步处理发送图片没有进度的问题 ([00e80a2](https://review.byted.org/#/q/00e80a2)), closes [#3496](https://jira.bytedance.com/browse/LKI-3496)
* **message:** 解决resolver使用错误导致的崩溃问题 ([c79487b](https://review.byted.org/#/q/c79487b)), closes [#3506](https://jira.bytedance.com/browse/LKI-3506)
* **message:** 解决发送优化调整后，文件消息发送可能错误显示loading态的问题 ([0e48fdc](https://review.byted.org/#/q/0e48fdc)), closes [#3369](https://jira.bytedance.com/browse/LKI-3369)
* **mine:** 修复minevc headview布局不正确 ([3debd8e](https://review.byted.org/#/q/3debd8e)), closes [#3481](https://jira.bytedance.com/browse/LKI-3481)
* **voip:** 1. 修改voip提示字符串 2. 更新ByteRTCSDK 并且适配。3. 更新ByteView模块 ([aa01393](https://review.byted.org/#/q/aa01393)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **voip:** 加速Bytertc engine dns 解析 ([d02bfc6](https://review.byted.org/#/q/d02bfc6)), closes [#934745239130316](https://jira.bytedance.com/browse/LKI-934745239130316)
* **web:** GetAppLanguage register ([323d8e9](https://review.byted.org/#/q/323d8e9)), closes [#3150](https://jira.bytedance.com/browse/LKI-3150)


### Features

* **byteview:** 加速ByteView启动时间 ([b1cc08d](https://review.byted.org/#/q/b1cc08d)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **byteview:** 实现将rust埋点信息传递到tea ([1d95af7](https://review.byted.org/#/q/1d95af7)), closes [#934745239130313](https://jira.bytedance.com/browse/LKI-934745239130313)
* **byteview:** 更新版本到0.5.2, 增加1.18 beta中的bug修复代码 ([d1a3a25](https://review.byted.org/#/q/d1a3a25)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **byteview:** 采用Monitor的metric接口 ([ac5dc05](https://review.byted.org/#/q/ac5dc05)), closes [#934745239130313](https://jira.bytedance.com/browse/LKI-934745239130313)
* **chat:**  将用户启动引导的控制放在keychain中 ([29be73a](https://review.byted.org/#/q/29be73a)), closes [#3911](https://jira.bytedance.com/browse/LKI-3911)
* **chat:**  用户引导UI修改 ([71fe7af](https://review.byted.org/#/q/71fe7af)), closes [#3911](https://jira.bytedance.com/browse/LKI-3911)
* **chat:**  调整UI初始化线程 ([9ace7dc](https://review.byted.org/#/q/9ace7dc)), closes [#3911](https://jira.bytedance.com/browse/LKI-3911)
* **chat:** :  修改启动引导逻辑，冷却时间0秒 ([cc5c0b7](https://review.byted.org/#/q/cc5c0b7)), closes [#3911](https://jira.bytedance.com/browse/LKI-3911)
* **chat:** reaction添加人查看优化 ([0891dbf](https://review.byted.org/#/q/0891dbf)), closes [#3449](https://jira.bytedance.com/browse/LKI-3449)
* **chat:** reaction添加人查看优化:  add LoadingView && loadFailView ([ac6d22f](https://review.byted.org/#/q/ac6d22f)), closes [#3449](https://jira.bytedance.com/browse/LKI-3449)
* **chat:** reaction添加人查看优化：生成Reaction·Detail 列表 ([e0ef71a](https://review.byted.org/#/q/e0ef71a)), closes [#3449](https://jira.bytedance.com/browse/LKI-3449)
* **chat:** 修改bubbleView字体大小 ([46e824a](https://review.byted.org/#/q/46e824a)), closes [#3911](https://jira.bytedance.com/browse/LKI-3911)
* **chat:** 修改附件icon，修改保存个人二维码image样式 ([e4b8fb2](https://review.byted.org/#/q/e4b8fb2)), closes [#3405](https://jira.bytedance.com/browse/LKI-3405)
* **chat:** 屏蔽chatVC电话入口，修改电话icon ([6b58d61](https://review.byted.org/#/q/6b58d61)), closes [#3405](https://jira.bytedance.com/browse/LKI-3405)
* **chat:** 提交对LarkGuide的引用，podfile以及podspec修改 ([44728d5](https://review.byted.org/#/q/44728d5)), closes [#3391](https://jira.bytedance.com/browse/LKI-3391)
* **chat:** 本人发出的消息气泡区分优化,  替换长消息压缩蒙版 ([33e001a](https://review.byted.org/#/q/33e001a)), closes [#3401](https://jira.bytedance.com/browse/LKI-3401)
* **chat:** 根据不同网络级别，消息发送loading选择不同策略 ([ffc0868](https://review.byted.org/#/q/ffc0868)), closes [#3371](https://jira.bytedance.com/browse/LKI-3371)
* **chat:** 添加修改群公告错误提示 ([7b8e02d](https://review.byted.org/#/q/7b8e02d)), closes [#3452](https://jira.bytedance.com/browse/LKI-3452)
* **component:** 支持打开zoom ([808e949](https://review.byted.org/#/q/808e949)), closes [#3474](https://jira.bytedance.com/browse/LKI-3474)
* **component:** 标签样式优化 ([2712495](https://review.byted.org/#/q/2712495)), closes [#3356](https://jira.bytedance.com/browse/LKI-3356)
* **component:** 标签样式优化 ([3d8af64](https://review.byted.org/#/q/3d8af64)), closes [#3356](https://jira.bytedance.com/browse/LKI-3356)
* **component:** 标签样式优化 ([28ac660](https://review.byted.org/#/q/28ac660)), closes [#3356](https://jira.bytedance.com/browse/LKI-3356)
* **contact:** 修改个人名片页拉取信息，添加同步拉取 ([2a9481a](https://review.byted.org/#/q/2a9481a)), closes [#3461](https://jira.bytedance.com/browse/LKI-3461)
* **docs:** 首页改版&Bug Fixed ([1310c55](https://review.byted.org/#/q/1310c55))
* **feed:** 启动埋点 perf_boot_start 增加参数，区分voip启动 ([c0a8756](https://review.byted.org/#/q/c0a8756)), closes [#3498](https://jira.bytedance.com/browse/LKI-3498)
* **feed:** 新增引导控件 ([caf8010](https://review.byted.org/#/q/caf8010)), closes [#3911](https://jira.bytedance.com/browse/LKI-3911)
* **feed:** 调整图片资源 ([7f861a1](https://review.byted.org/#/q/7f861a1)), closes [#3911](https://jira.bytedance.com/browse/LKI-3911)
* **file:** Lark文件预览与应用内打开- 文件下载打开优化 ([a166909](https://review.byted.org/#/q/a166909)), closes [#3464](https://jira.bytedance.com/browse/LKI-3464)
* **file:** 优化文件相关逻辑 ([4d95153](https://review.byted.org/#/q/4d95153)), closes [#3460](https://jira.bytedance.com/browse/LKI-3460)
* **file:** 在下载页面，如果文件被撤回，弹出弹框提示用户 ([92e3d66](https://review.byted.org/#/q/92e3d66)), closes [#3464](https://jira.bytedance.com/browse/LKI-3464)
* **file:** 文件最大上限提示的中文文案修改 ([fecb18f](https://review.byted.org/#/q/fecb18f)), closes [#3466](https://jira.bytedance.com/browse/LKI-3466)
* **file:** 文件相关打点需求 ([582ee73](https://review.byted.org/#/q/582ee73)), closes [#3493](https://jira.bytedance.com/browse/LKI-3493)
* Calendar 1.19.4 ([29f4ec9](https://review.byted.org/#/q/29f4ec9))
* **file:** 文件预览页面，增加menuOptionSet，不同来源可以定制menu内容 ([f022575](https://review.byted.org/#/q/f022575)), closes [#3464](https://jira.bytedance.com/browse/LKI-3464)
* **foundation:** 增加用户引导云控，5分钟冷却机制 ([9c30845](https://review.byted.org/#/q/9c30845)), closes [#3199](https://jira.bytedance.com/browse/LKI-3199)
* remove 0.1s delay of event description ([825138b](https://review.byted.org/#/q/825138b))
* support add external event attendee ([65d8f14](https://review.byted.org/#/q/65d8f14))
* **message:** 失败消息本地push对接 ([72cb482](https://review.byted.org/#/q/72cb482)), closes [#3371](https://jira.bytedance.com/browse/LKI-3371)
* **message:** 接入bitable ([76b6e6d](https://review.byted.org/#/q/76b6e6d)), closes [#3359](https://jira.bytedance.com/browse/LKI-3359)
* **microapp:** 小程序扩展lark中选择本地附件的接口filePicker,支持最大选择数的控制 closes [#3472](https://jira.bytedance.com/browse/LKI-3472) ([0cf7296](https://review.byted.org/#/q/0cf7296))
* **rust:**  新增用户引导的接口(push & request) ([2a063c0](https://review.byted.org/#/q/2a063c0)), closes [#3391](https://jira.bytedance.com/browse/LKI-3391)
* **web:** jssdk 支持获取language接口 && fix setRight第一次设置true无法展示rightButton的bug ([3776208](https://review.byted.org/#/q/3776208)), closes [#3150](https://jira.bytedance.com/browse/LKI-3150)



<a name="1.18.1"></a>
## 1.18.1 (2018-12-11)


### Features

* **byteview:** update byteview from 0.5.0-alpha2 to 0.5.0-alpha3 ([88ff920](https://review.byted.org/#/q/88ff920)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **byteview:** 同设备VC或者VOIP小窗时，避免创建新的VC和VOIP ([72b5a3d](https://review.byted.org/#/q/72b5a3d)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **component:** 支持打开zoom ([f08fda2](https://review.byted.org/#/q/f08fda2)), closes [#3474](https://jira.bytedance.com/browse/LKI-3474)
* **contact:**  添加chatter.accessInfo，并屏蔽chat，personcard电话入口 ([21f42c1](https://review.byted.org/#/q/21f42c1)), closes [#3469](https://jira.bytedance.com/browse/LKI-3469)
* **file:** 文件icon优化 ([3f190f4](https://review.byted.org/#/q/3f190f4)), closes [#3460](https://jira.bytedance.com/browse/LKI-3460)
* **file:** 更新LarkFoundation,增加对不同视频格式判断逻辑 ([9a69f0a](https://review.byted.org/#/q/9a69f0a)), closes [#3375](https://jira.bytedance.com/browse/LKI-3375)
* **file:** 本地文件选择支持上限 ([fb8dfb8](https://review.byted.org/#/q/fb8dfb8)), closes [#3466](https://jira.bytedance.com/browse/LKI-3466)
* **message:** 直接使用 data count 计算 PCM 音频时长 ([7af332e](https://review.byted.org/#/q/7af332e)), closes [#3408](https://jira.bytedance.com/browse/LKI-3408)


### Performance Improvements

* **account:** 容器初始化提前、异步 ([46f8ffd](https://review.byted.org/#/q/46f8ffd)), closes [#3467](https://jira.bytedance.com/browse/LKI-3467)



<a name="1.18.0"></a>
# 1.18.0 (2018-12-10)


### Bug Fixes

* **account:** 登录后冷启动l没有注册远程通知 ([cce3216](https://review.byted.org/#/q/cce3216)), closes [#3455](https://jira.bytedance.com/browse/LKI-3455)
* **byteview:**  单人密聊对视频通话消息出现在非密聊页面 ([e6aa09f](https://review.byted.org/#/q/e6aa09f)), closes [#923806023201632](https://jira.bytedance.com/browse/LKI-923806023201632)
* **byteview:** 修复用户退出登陆以后仍在视频通话问题 ([8b5d28e](https://review.byted.org/#/q/8b5d28e)), closes [#3393](https://jira.bytedance.com/browse/LKI-3393)
* **byteview:** 视频通话同时点击取消与接通时，主叫画面卡死 ([a315081](https://review.byted.org/#/q/a315081)), closes [#3422](https://jira.bytedance.com/browse/LKI-3422)
* **byteview:** 视频通话同时点击取消与接通时，被叫画面卡死 ([0d1556e](https://review.byted.org/#/q/0d1556e)), closes [#3422](https://jira.bytedance.com/browse/LKI-3422)
* **chat:** 1.18beta Chat页面崩溃率上升问题 ([d40b30b](https://review.byted.org/#/q/d40b30b)), closes [#3404](https://jira.bytedance.com/browse/LKI-3404)
* **chat:** 修复chat电话入口无视频的bug ([4cdcd3f](https://review.byted.org/#/q/4cdcd3f)), closes [#3382](https://jira.bytedance.com/browse/LKI-3382)
* **chat:** 修复单聊无自动翻译设置，自己消息被翻译，富文本折叠地球view被遮挡的bug ([0c0a416](https://review.byted.org/#/q/0c0a416)), closes [#3136](https://jira.bytedance.com/browse/LKI-3136)
* **chat:** 修正不可见消息需求引入的，chat页面上拉加载更多边界判断可能不准的问题 ([f8e24c1](https://review.byted.org/#/q/f8e24c1)), closes [#3400](https://jira.bytedance.com/browse/LKI-3400)
* **chat:** 修正向下拉取消息数量，防止越界，导致与feed预加载预期不符合 ([43219a6](https://review.byted.org/#/q/43219a6)), closes [#3443](https://jira.bytedance.com/browse/LKI-3443)
* **chat:** 修正拉取消息本地校验边界逻辑 ([004fb44](https://review.byted.org/#/q/004fb44)), closes [#3443](https://jira.bytedance.com/browse/LKI-3443)
* **chat:** 修正支持不可见消息后，定位到最远未读首屏加载策略（改为向后拉 ([25257e9](https://review.byted.org/#/q/25257e9)), closes [#3411](https://jira.bytedance.com/browse/LKI-3411)
* **chat:** 回复状态下，消息刷新，页面位置会移动 ([ace8e0e](https://review.byted.org/#/q/ace8e0e)), closes [#3135](https://jira.bytedance.com/browse/LKI-3135)
* **chat:** 在iOS上清空群公告，会发出一条内容为空的富文本消息 ([a43114a](https://review.byted.org/#/q/a43114a)), closes [#3445](https://jira.bytedance.com/browse/LKI-3445)
* **chat:** 系统消息格式错误 ([461358c](https://review.byted.org/#/q/461358c)), closes [#3392](https://jira.bytedance.com/browse/LKI-3392)
* **chat:** 解决chat页面chatmsgvm循环引用问题 ([ae3310b](https://review.byted.org/#/q/ae3310b)), closes [#3439](https://jira.bytedance.com/browse/LKI-3439)
* **chat:** 解决发送消息时，偶发下拉加载更多状态ui错误显示问题 ([cdd6d95](https://review.byted.org/#/q/cdd6d95)), closes [#3403](https://jira.bytedance.com/browse/LKI-3403)
* **chat:** 解决断网重连后在主线程修改了数据源的问题 ([c116ad3](https://review.byted.org/#/q/c116ad3)), closes [#3433](https://jira.bytedance.com/browse/LKI-3433)
* **component:** 修复 “有新版”标签过大； 更新LarkUIKit ([7dd5189](https://review.byted.org/#/q/7dd5189)), closes [#3373](https://jira.bytedance.com/browse/LKI-3373)
* **component:** 修复重装不会重新申请通知权限 BUG ([4c64480](https://review.byted.org/#/q/4c64480)), closes [#3351](https://jira.bytedance.com/browse/LKI-3351)
* **component:** 横屏启动是启动图不应该横屏 ([f3369a1](https://review.byted.org/#/q/f3369a1)), closes [#3374](https://jira.bytedance.com/browse/LKI-3374)
* **component:** 点加急卡片内容会收起卡片，而不是定位到消息 ([39c6c49](https://review.byted.org/#/q/39c6c49)), closes [#3420](https://jira.bytedance.com/browse/LKI-3420)
* **component:** 登录选择企业界面，”重新登录“按钮失效 ([547da0f](https://review.byted.org/#/q/547da0f)), closes [#3354](https://jira.bytedance.com/browse/LKI-3354)
* **component:** 解决通过feed页状态栏直接进入账户页面，通知设置状态不对的问题 ([f7e0aee](https://review.byted.org/#/q/f7e0aee)), closes [#3459](https://jira.bytedance.com/browse/LKI-3459)
* **contact:**  请假标签Ui不正确，workday设置英文提示不正确 ([11fda3a](https://review.byted.org/#/q/11fda3a)), closes [#3394](https://jira.bytedance.com/browse/LKI-3394)
* **contact:** 修复search复用导致标签显示不正确 ([57df48e](https://review.byted.org/#/q/57df48e)), closes [#3417](https://jira.bytedance.com/browse/LKI-3417)
* **contact:** 修复workday开始与结束为同一天显示不正确 ([2da305e](https://review.byted.org/#/q/2da305e)), closes [#3376](https://jira.bytedance.com/browse/LKI-3376)
* **contact:** 修复workday标签不正确 ([5e2b6e0](https://review.byted.org/#/q/5e2b6e0)), closes [#3102](https://jira.bytedance.com/browse/LKI-3102)
* **contact:** 修改个人名片页入口图标 ([e3c1d43](https://review.byted.org/#/q/e3c1d43)), closes [#3425](https://jira.bytedance.com/browse/LKI-3425)
* **docs:** sheet表格打开无法输入&键盘事件处理 ([7aadce3](https://review.byted.org/#/q/7aadce3))
* **feed:** docs外部标签样式不统一 ([8bc6b60](https://review.byted.org/#/q/8bc6b60)), closes [#3390](https://jira.bytedance.com/browse/LKI-3390)
* **feed:** 修复进前台 application badge 不更新的问题 ([61cadba](https://review.byted.org/#/q/61cadba)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **feed:** 修改feed首页cell约束冲突 ([6b3ef75](https://review.byted.org/#/q/6b3ef75)), closes [#3323](https://jira.bytedance.com/browse/LKI-3323)
* **finance:** 修复红包文案问题，添加打点 ([36a9e86](https://review.byted.org/#/q/36a9e86)), closes [#3384](https://jira.bytedance.com/browse/LKI-3384)
* **finance:** 修复红包精度问题 ([3adeb7e](https://review.byted.org/#/q/3adeb7e)), closes [#3350](https://jira.bytedance.com/browse/LKI-3350)
* **finance:** 财经callback线程调整 ([22672d1](https://review.byted.org/#/q/22672d1)), closes [#3398](https://jira.bytedance.com/browse/LKI-3398)
* **forward:** 修复转发确认后搜索键盘不会消失bug ([dcaf1f4](https://review.byted.org/#/q/dcaf1f4)), closes [#3307](https://jira.bytedance.com/browse/LKI-3307)
* **forward:** 修复转发默认数据可以加载更多，键盘遮挡弹窗问题 ([7c7391f](https://review.byted.org/#/q/7c7391f)), closes [#3307](https://jira.bytedance.com/browse/LKI-3307)
* **forward:** 日历分享过滤器不正确 ([2214d83](https://review.byted.org/#/q/2214d83)), closes [#3431](https://jira.bytedance.com/browse/LKI-3431)
* **message:** 修复会话列表消息 cell 取消选中态 不可点击 BUG ([13a2c90](https://review.byted.org/#/q/13a2c90)), closes [#3380](https://jira.bytedance.com/browse/LKI-3380)
* **message:** 修复草稿多线程造成的崩溃问题 ([47b007b](https://review.byted.org/#/q/47b007b)), closes [#3341](https://jira.bytedance.com/browse/LKI-3341)
* **message:** 处理 pin 数据重复的问题 ([55562c8](https://review.byted.org/#/q/55562c8)), closes [#3355](https://jira.bytedance.com/browse/LKI-3355)
* wording change in permission ([8875868](https://review.byted.org/#/q/8875868))
* **message:** 贴子消息已读折叠问题 ([1f035ed](https://review.byted.org/#/q/1f035ed)), closes [#3366](https://jira.bytedance.com/browse/LKI-3366)
* **microapp:** [EESPM-1319]移除TTMicroApp组件引入的crash收集相关的组件依赖 ([7bf9180](https://review.byted.org/#/q/7bf9180))
* **microapp:** 修复头条圈相机权限关闭后不能发评论的问题 close 3423 ([1ad2bb7](https://review.byted.org/#/q/1ad2bb7))
* **mine:** 修复群成员列表无法显示请假 ([1239875](https://review.byted.org/#/q/1239875)), closes [#3102](https://jira.bytedance.com/browse/LKI-3102)
* **mine:** 修复请假引导页模糊bug ([0ebd11a](https://review.byted.org/#/q/0ebd11a)), closes [#3102](https://jira.bytedance.com/browse/LKI-3102)
* **search:** 修改点击组织架构，搜索，点击取消，没有反应的问题 ([5555ed3](https://review.byted.org/#/q/5555ed3)), closes [#3352](https://jira.bytedance.com/browse/LKI-3352)
* **search:** 更新LarkUIKit,启用release分支,解决搜索框不显示x的bug ([10d259b](https://review.byted.org/#/q/10d259b)), closes [#3407](https://jira.bytedance.com/browse/LKI-3407)
* **search:** 解决如果chatter没有返回数据，后续结果都不展示的问题 ([45a30f0](https://review.byted.org/#/q/45a30f0)), closes [#3358](https://jira.bytedance.com/browse/LKI-3358)
* **voip:** calling 不走超时逻辑 ([b842d08](https://review.byted.org/#/q/b842d08)), closes [#3360](https://jira.bytedance.com/browse/LKI-3360)
* **voip:** iOS 主叫忙线Toast显示错误 ([c389b5c](https://review.byted.org/#/q/c389b5c)), closes [#3454](https://jira.bytedance.com/browse/LKI-3454)
* **voip:** VoIP监控报警没有走Slardar事件报警 ([f8a9a46](https://review.byted.org/#/q/f8a9a46)), closes [#3426](https://jira.bytedance.com/browse/LKI-3426)
* **voip:** 修复voip后台挂起不响铃问题。 ([c338709](https://review.byted.org/#/q/c338709)), closes [#915075132074746](https://jira.bytedance.com/browse/LKI-915075132074746)
* **voip:** 结束时显示 call end toast ([d713aa0](https://review.byted.org/#/q/d713aa0)), closes [#930457350667458](https://jira.bytedance.com/browse/LKI-930457350667458)
* **web:** People链接打开相对路径的问题 ([93f4bfe](https://review.byted.org/#/q/93f4bfe)), closes [#3365](https://jira.bytedance.com/browse/LKI-3365)
* **web:** 修复扫一扫，扫描结果太快，容易卡死的问题 ([b242589](https://review.byted.org/#/q/b242589)), closes [#3406](https://jira.bytedance.com/browse/LKI-3406)
* [EESPM-1332] 小程序图片查看预览图失效 ([7f286dd](https://review.byted.org/#/q/7f286dd))
* [EESPM-1358]修复zfplayer代码被覆盖问题和评论不能匿名问题 ([c9c774d](https://review.byted.org/#/q/c9c774d))


### Features

* **account:** 多租户UI and 接口，联调完毕 ([ec3f905](https://review.byted.org/#/q/ec3f905)), closes [#3193](https://jira.bytedance.com/browse/LKI-3193)
* **byteview:** VC入口图标替换&&无网络提示 ([289095e](https://review.byted.org/#/q/289095e)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **byteview:** 无网络toast提示移至ByteView ([1bb7933](https://review.byted.org/#/q/1bb7933)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **Calendar:** Calendar 1.18.5 ([c9dbbb2](https://review.byted.org/#/q/c9dbbb2))
* **chat:**  添加自动翻译action ([1138962](https://review.byted.org/#/q/1138962)), closes [#3136](https://jira.bytedance.com/browse/LKI-3136)
* **chat:** 本人发出的消息气泡区分优化:  替换别人发出的消息的气泡背景 ([d433d7c](https://review.byted.org/#/q/d433d7c)), closes [#3401](https://jira.bytedance.com/browse/LKI-3401)
* **chat:** 消息不可见新策略对接 ([ae39fbd](https://review.byted.org/#/q/ae39fbd)), closes [#3333](https://jira.bytedance.com/browse/LKI-3333)
* **chat:** 添加自动翻译引导页 ([a3f7a37](https://review.byted.org/#/q/a3f7a37)), closes [#3136](https://jira.bytedance.com/browse/LKI-3136)
* **chat:** 添加自动翻译打点，更新rustPB,message中加入isUntranslateable字段 ([45f6de1](https://review.byted.org/#/q/45f6de1)), closes [#3136](https://jira.bytedance.com/browse/LKI-3136)
* **chat:** 添加自动翻译群设置以及fg ([200a07b](https://review.byted.org/#/q/200a07b)), closes [#3136](https://jira.bytedance.com/browse/LKI-3136)
* **chat:** 翻译添加isAutoTranslate字段 ([a84c7b6](https://review.byted.org/#/q/a84c7b6)), closes [#3102](https://jira.bytedance.com/browse/LKI-3102)
* **chat:** 进退群消息可点击,修复文字不居中的·问题 ([a329bed](https://review.byted.org/#/q/a329bed)), closes [#3246](https://jira.bytedance.com/browse/LKI-3246)
* **chat:** 进退群消息可点击，兼容旧的数据 ([bfde54a](https://review.byted.org/#/q/bfde54a)), closes [#3349](https://jira.bytedance.com/browse/LKI-3349)
* **chat:** 进退群消息可点击、埋点 ([ff9ca93](https://review.byted.org/#/q/ff9ca93)), closes [#3246](https://jira.bytedance.com/browse/LKI-3246) [#3347](https://jira.bytedance.com/browse/LKI-3347) [#3349](https://jira.bytedance.com/browse/LKI-3349)
* **component:** 优化财经模块初始化 ([6a98304](https://review.byted.org/#/q/6a98304)), closes [#3427](https://jira.bytedance.com/browse/LKI-3427)
* **component:** 标签样式优化 ([df3b609](https://review.byted.org/#/q/df3b609)), closes [#3198](https://jira.bytedance.com/browse/LKI-3198)
* **component:** 标签样式优化 回滚“密聊”标签 ([02f237d](https://review.byted.org/#/q/02f237d)), closes [#3198](https://jira.bytedance.com/browse/LKI-3198)
* **component:** 添加 prerelease 环境切换机房接口 ([bad051a](https://review.byted.org/#/q/bad051a)), closes [#3428](https://jira.bytedance.com/browse/LKI-3428)
* **component:** 添加上传 slardar dsym 脚本 ([b0f9ef0](https://review.byted.org/#/q/b0f9ef0)), closes [#3353](https://jira.bytedance.com/browse/LKI-3353)
* **component:** 添加部分 Feed Chat 性能打点, 以及一些性能打点工具 ([8504366](https://review.byted.org/#/q/8504366)), closes [#3081](https://jira.bytedance.com/browse/LKI-3081)
* **contact:** 转换itempickeritem为forwardItem ([834c09a](https://review.byted.org/#/q/834c09a)), closes [#3307](https://jira.bytedance.com/browse/LKI-3307)
* **docs:** update DocsSDK && support create docs in lark main page && fix build error ([d70696d](https://review.byted.org/#/q/d70696d))
* **docs:** 当在Lark中点击 doc/sheet 文档链接 到浏览器时，在URL后追加参数，提供更多来路信息 ([8c48530](https://review.byted.org/#/q/8c48530)), closes [#3207](https://jira.bytedance.com/browse/LKI-3207)
* **feed:**   添加引导图图片以及启动引导功能-1 ([a89a0f0](https://review.byted.org/#/q/a89a0f0)), closes [#3391](https://jira.bytedance.com/browse/LKI-3391)
* **feed:** 全局网络状态交互方案优化 ([6373e6a](https://review.byted.org/#/q/6373e6a)), closes [#3368](https://jira.bytedance.com/browse/LKI-3368)
* **feed:** 启动引导图滑动效果修改 ([1980aa0](https://review.byted.org/#/q/1980aa0)), closes [#3391](https://jira.bytedance.com/browse/LKI-3391)
* **file:** 本地打开文件 ([efea250](https://review.byted.org/#/q/efea250)), closes [#3375](https://jira.bytedance.com/browse/LKI-3375)
* **file:** 选择附件本地文件增加一个最大的选择数量的参数 ([7c7c91f](https://review.byted.org/#/q/7c7c91f)), closes [#3456](https://jira.bytedance.com/browse/LKI-3456)
* **finance:** 优化paymanager 初始化 ([02a229c](https://review.byted.org/#/q/02a229c)), closes [#3434](https://jira.bytedance.com/browse/LKI-3434)
* **finance:** 增加两个红包相关埋点 ([d1ffe1a](https://review.byted.org/#/q/d1ffe1a)), closes [#3070](https://jira.bytedance.com/browse/LKI-3070) [#3071](https://jira.bytedance.com/browse/LKI-3071)
* **finance:** 红包转动效果调整 ([01dd6df](https://review.byted.org/#/q/01dd6df)), closes [#2955](https://jira.bytedance.com/browse/LKI-2955)
* **forward:** 修复forwardVC search不能加载更多以及选择超限 ([4b9543a](https://review.byted.org/#/q/4b9543a)), closes [#3307](https://jira.bytedance.com/browse/LKI-3307)
* **forward:** 修改ForwardItem添加isCrypto，修改createGroupRequest，实现转发逻辑 ([2739156](https://review.byted.org/#/q/2739156)), closes [#3307](https://jira.bytedance.com/browse/LKI-3307)
* **forward:** 添加搜索相关逻辑 ([99dae9d](https://review.byted.org/#/q/99dae9d)), closes [#3307](https://jira.bytedance.com/browse/LKI-3307)
* **forward:** 添加转发列表打点 ([f7a3bc4](https://review.byted.org/#/q/f7a3bc4)), closes [#3328](https://jira.bytedance.com/browse/LKI-3328)
* **message:** 聊天页菜单新 UI ([0d14f34](https://review.byted.org/#/q/0d14f34)), closes [#3282](https://jira.bytedance.com/browse/LKI-3282)
* tabBar支持添加自定义view ([48d5860](https://review.byted.org/#/q/48d5860))
* **message:** 聊天页菜单添加选中状态 ([b589069](https://review.byted.org/#/q/b589069)), closes [#3282](https://jira.bytedance.com/browse/LKI-3282)
* **mine:** 添加mine workday打点 ([1861eb4](https://review.byted.org/#/q/1861eb4)), closes [#3102](https://jira.bytedance.com/browse/LKI-3102)
* **search:** 搜索去掉值班号cell中的耳机图标，更新LarkUIKit ([23fc1b4](https://review.byted.org/#/q/23fc1b4)), closes [#3317](https://jira.bytedance.com/browse/LKI-3317)
* **search:** 搜索新增埋点 ([8c21f20](https://review.byted.org/#/q/8c21f20)), closes [#3330](https://jira.bytedance.com/browse/LKI-3330)
* **voip:** Lark应用内颜色调整(VoIP ([207610b](https://review.byted.org/#/q/207610b)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **voip:** 创建Voip前无网络toast ([e5d95a2](https://review.byted.org/#/q/e5d95a2)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **web:** 扫码链接自动检测 ([684c815](https://review.byted.org/#/q/684c815)), closes [#3372](https://jira.bytedance.com/browse/LKI-3372)


### Performance Improvements

* **account:** 快速启动时SDK只初始化一次 ([a25a651](https://review.byted.org/#/q/a25a651)), closes [#3463](https://jira.bytedance.com/browse/LKI-3463)



<a name="1.17.0"></a>
# 1.17.0 (2018-11-30)


### Bug Fixes

* **byteview:** 1v1视频通话意外中断（两次） ([ecb1a05](https://review.byted.org/#/q/ecb1a05)), closes [#3252](https://jira.bytedance.com/browse/LKI-3252)
* **byteview:** iOS在最小化视频通话时，点击对话框的图片，扬声器会被关掉 ([304e2d4](https://review.byted.org/#/q/304e2d4)), closes [#3273](https://jira.bytedance.com/browse/LKI-3273)
* **byteview:** 单人视频会议无法看到自己画面 ([103bd71](https://review.byted.org/#/q/103bd71)), closes [#3325](https://jira.bytedance.com/browse/LKI-3325)
* **calendar:** 修复日历使用Docs的崩溃 ([67e859c](https://review.byted.org/#/q/67e859c))
* **chat:** ChatNaviTitleBar 未读消息数字显示错误 ([19bd1ae](https://review.byted.org/#/q/19bd1ae)), closes [#3340](https://jira.bytedance.com/browse/LKI-3340)
* **chat:** 修复'点击单聊会话Title会进入群设置' ([8cb16a0](https://review.byted.org/#/q/8cb16a0)), closes [#3244](https://jira.bytedance.com/browse/LKI-3244)
* **chat:** 修正昵称+备注显示规则 ([cb85a61](https://review.byted.org/#/q/cb85a61)), closes [#3043](https://jira.bytedance.com/browse/LKI-3043)
* **chat:** 单聊建群分享权限时，默认建议权限，各端实现不一致 ([c79dac6](https://review.byted.org/#/q/c79dac6)), closes [#3227](https://jira.bytedance.com/browse/LKI-3227)
* **chat:** 单聊窗口顶部人名下方加一行签名, 修复布局问题 ([aa4186d](https://review.byted.org/#/q/aa4186d)), closes [#3169](https://jira.bytedance.com/browse/LKI-3169)
* **chat:** 小程序发起聊天回退，堆栈不对，docs部分无法进入名片页 ([5d199e6](https://review.byted.org/#/q/5d199e6)), closes [#3206](https://jira.bytedance.com/browse/LKI-3206) [#3205](https://jira.bytedance.com/browse/LKI-3205)
* **component:** TTTracker 使用  TOB 版本 ([ad48e9e](https://review.byted.org/#/q/ad48e9e)), closes [#3234](https://jira.bytedance.com/browse/LKI-3234)
* **component:** 修复 staging feature id 问题 ([6f9782e](https://review.byted.org/#/q/6f9782e)), closes [#3335](https://jira.bytedance.com/browse/LKI-3335)
* **component:** 修复 sticker 管理页面选择图片空白问题 ([416e339](https://review.byted.org/#/q/416e339)), closes [#3299](https://jira.bytedance.com/browse/LKI-3299)
* **component:** 修复从Feed，+ 进入群聊退群失败 ([f00f11f](https://review.byted.org/#/q/f00f11f)), closes [#2529](https://jira.bytedance.com/browse/LKI-2529)
* **component:** 修复头条圈评论不能选择匿名的问题 closes [#3324](https://jira.bytedance.com/browse/LKI-3324) ([c7ec154](https://review.byted.org/#/q/c7ec154))
* **component:** 调整ShareExtension NavigationBar 样式，以适应深色NavigationBar的App的分享 ([64d1d77](https://review.byted.org/#/q/64d1d77)), closes [#3170](https://jira.bytedance.com/browse/LKI-3170)
* **contact:** (1)设置备注支持默认显示，并调整设计 (2)备注名加入校验逻辑 ([a7d4132](https://review.byted.org/#/q/a7d4132)), closes [#3259](https://jira.bytedance.com/browse/LKI-3259)
* **contact:** 修复oncall searchbug ([021e7ae](https://review.byted.org/#/q/021e7ae)), closes [#3192](https://jira.bytedance.com/browse/LKI-3192)
* **contact:** 修复oncall UI Bug ([a876715](https://review.byted.org/#/q/a876715)), closes [#3192](https://jira.bytedance.com/browse/LKI-3192)
* **contact:** 修复oncall UI不正确 ([7f1a18f](https://review.byted.org/#/q/7f1a18f)), closes [#3192](https://jira.bytedance.com/browse/LKI-3192)
* **contact:** 修复personcard url不正确 ([be066ac](https://review.byted.org/#/q/be066ac)), closes [#3267](https://jira.bytedance.com/browse/LKI-3267)
* **contact:** 修复recall不可点击头像的bug ([679d1a9](https://review.byted.org/#/q/679d1a9)), closes [#3166](https://jira.bytedance.com/browse/LKI-3166)
* **contact:** 修复search不正确 ([5c2f323](https://review.byted.org/#/q/5c2f323)), closes [#3192](https://jira.bytedance.com/browse/LKI-3192)
* **contact:** 修复个人名片页不能查看原图的bug ([8b78bb5](https://review.byted.org/#/q/8b78bb5)), closes [#3295](https://jira.bytedance.com/browse/LKI-3295)
* **contact:** 修复修改昵称无法退出当前页以及群备注显示不正确 ([18b4178](https://review.byted.org/#/q/18b4178)), closes [#3192](https://jira.bytedance.com/browse/LKI-3192)
* **contact:** 修复拉取oncall列表不正确 ([fbcb6f3](https://review.byted.org/#/q/fbcb6f3)), closes [#3250](https://jira.bytedance.com/browse/LKI-3250)
* **contact:** 修复无法拉回请假状态 ([4781a00](https://review.byted.org/#/q/4781a00)), closes [#3102](https://jira.bytedance.com/browse/LKI-3102)
* **contact:** 修复标签显示不正确 ([d42405b](https://review.byted.org/#/q/d42405b)), closes [#3192](https://jira.bytedance.com/browse/LKI-3192)
* **contact:** 修复选择电话号码区号适配问题以及点击蒙层可以关闭 ([20192f6](https://review.byted.org/#/q/20192f6)), closes [#3182](https://jira.bytedance.com/browse/LKI-3182)
* **contact:** 修复邀请卡片布局不正确 ([3b43ece](https://review.byted.org/#/q/3b43ece)), closes [#3337](https://jira.bytedance.com/browse/LKI-3337)
* **contact:** 修复非好友下标签显示不正确的bug ([eed0fde](https://review.byted.org/#/q/eed0fde)), closes [#3307](https://jira.bytedance.com/browse/LKI-3307)
* **contact:** 修复非好友有密聊入口 ([113218a](https://review.byted.org/#/q/113218a)), closes [#3204](https://jira.bytedance.com/browse/LKI-3204)
* **contact:** 电话提示view的title显示问题 ([7d4cd30](https://review.byted.org/#/q/7d4cd30)), closes [#3199](https://jira.bytedance.com/browse/LKI-3199)
* **contact:** 调整收藏列表/建群/加群成员/单聊建群名称显示规则 ([abb5cdf](https://review.byted.org/#/q/abb5cdf)), closes [#3249](https://jira.bytedance.com/browse/LKI-3249)
* **docs:** 发送评论不能滚动 ([874a153](https://review.byted.org/#/q/874a153))
* **docs:** 权限申请Bug ([ec599ce](https://review.byted.org/#/q/ec599ce))
* **docs:** 预加载逻辑错误导致crash ([cfdd028](https://review.byted.org/#/q/cfdd028))
* **docs&calendar:** 回滚日历JS代码&评论遮挡问题 ([306fd0a](https://review.byted.org/#/q/306fd0a))
* **email:** 修复邮件可能显示不出来问题 ([ef79da4](https://review.byted.org/#/q/ef79da4)), closes [#3294](https://jira.bytedance.com/browse/LKI-3294)
* **feed:** Loading 时点击过滤器后 "Loading..." 会变为 "Inbox..." ([2c28926](https://review.byted.org/#/q/2c28926)), closes [#3183](https://jira.bytedance.com/browse/LKI-3183)
* **feed:** 置顶头像普通单聊和密聊没有区分 ([9503406](https://review.byted.org/#/q/9503406)), closes [#3179](https://jira.bytedance.com/browse/LKI-3179)
* **feed:** 解决iOS 10上，feedListVC的tableview多了一个-20的contentInset ([f299689](https://review.byted.org/#/q/f299689)), closes [#3184](https://jira.bytedance.com/browse/LKI-3184)
* **feed:** 跳下一个未读增加些 log ([2e0a641](https://review.byted.org/#/q/2e0a641)), closes [#3247](https://jira.bytedance.com/browse/LKI-3247)
* **file:** 解决UIWebView打开文件，底部出现黑边的问题 ([02b546a](https://review.byted.org/#/q/02b546a)), closes [#3232](https://jira.bytedance.com/browse/LKI-3232)
* **finance:** 修复打开红包后，点击“存入钱包”链接，没有反应 ([d9cad67](https://review.byted.org/#/q/d9cad67)), closes [#3343](https://jira.bytedance.com/browse/LKI-3343)
* **finance:** 修复抢红包时间格式不对的问题 ([d73c8c2](https://review.byted.org/#/q/d73c8c2)), closes [#3276](https://jira.bytedance.com/browse/LKI-3276)
* **finance:** 修复红包 cell 样式 ([05c9b0f](https://review.byted.org/#/q/05c9b0f)), closes [#3253](https://jira.bytedance.com/browse/LKI-3253)
* **finance:** 修复红包个数为0引起的崩溃问题 ([e783eac](https://review.byted.org/#/q/e783eac)), closes [#3211](https://jira.bytedance.com/browse/LKI-3211)
* **finance:** 修改文案 ([93ef69e](https://review.byted.org/#/q/93ef69e)), closes [#3279](https://jira.bytedance.com/browse/LKI-3279)
* **finance:** 修改红包显示日期格式 ([2d2b57a](https://review.byted.org/#/q/2d2b57a)), closes [#3240](https://jira.bytedance.com/browse/LKI-3240)
* **finance:** 修改红包领取后没有置灰的问题。 ([9b503ef](https://review.byted.org/#/q/9b503ef)), closes [#3213](https://jira.bytedance.com/browse/LKI-3213)
* **finance:** 钱包页余额单位中文版统一显示“元” ([8448e28](https://review.byted.org/#/q/8448e28)), closes [#2965](https://jira.bytedance.com/browse/LKI-2965)
* **finance:** 钱包页面请求余额时机改变 ([9467603](https://review.byted.org/#/q/9467603)), closes [#3258](https://jira.bytedance.com/browse/LKI-3258)
* **LarkTracer:** framework引入有问题 ([59eb7ba](https://review.byted.org/#/q/59eb7ba)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **message:** 1.群公告编辑人没显示昵称 2.加急确认页面修改显示策略 ([2636db5](https://review.byted.org/#/q/2636db5)), closes [#3290](https://jira.bytedance.com/browse/LKI-3290)
* **message:** 优化撤回重新编辑样式 ([bbc6744](https://review.byted.org/#/q/bbc6744)), closes [#3262](https://jira.bytedance.com/browse/LKI-3262)
* **message:** 修复@人失效问题 ([b5e79e1](https://review.byted.org/#/q/b5e79e1)), closes [#3133](https://jira.bytedance.com/browse/LKI-3133)
* **message:** 修正帖子转发确认框文案错误 ([c06b372](https://review.byted.org/#/q/c06b372)), closes [#3264](https://jira.bytedance.com/browse/LKI-3264)
* **message:** 卡片消息国际化 ([66c255e](https://review.byted.org/#/q/66c255e)), closes [#3118](https://jira.bytedance.com/browse/LKI-3118)
* **message:** 呼叫电话的系统消息，@人 无法点击出名片 ([d79de78](https://review.byted.org/#/q/d79de78)), closes [#3272](https://jira.bytedance.com/browse/LKI-3272)
* **message:** 密聊相关文案及ui调整 ([839286a](https://review.byted.org/#/q/839286a)), closes [#3242](https://jira.bytedance.com/browse/LKI-3242)
* **message:** 解决和自己的会话消息发送状态ui丢失问题 ([d433d90](https://review.byted.org/#/q/d433d90)), closes [#3256](https://jira.bytedance.com/browse/LKI-3256)
* **message:** 解决消息发送直接进入失败态时，消息不上屏的问题 ([c35c4df](https://review.byted.org/#/q/c35c4df)), closes [#3257](https://jira.bytedance.com/browse/LKI-3257)
* **search:** 中文搜索跳动太厉害了，在中文输入过程中不搜索 ([ddcee01](https://review.byted.org/#/q/ddcee01)), closes [#3305](https://jira.bytedance.com/browse/LKI-3305)
* **search:** 在搜索完成的时候，判断一下如果搜的词和当前的text不一样，则不提示无结果 ([c15594a](https://review.byted.org/#/q/c15594a)), closes [#3304](https://jira.bytedance.com/browse/LKI-3304)
* **search:** 搜索键盘换行改为搜索 ([c48200a](https://review.byted.org/#/q/c48200a)), closes [#3285](https://jira.bytedance.com/browse/LKI-3285)
* **voip:** 1. 修改端上一直处于忙线bug 2. 提前初始化SDK加快连接速度 ([efb856d](https://review.byted.org/#/q/efb856d)), closes [#920103965688335](https://jira.bytedance.com/browse/LKI-920103965688335)
* **voip:** 1. 修改端上一直处于忙线bug 2. 提前初始化SDK加快连接速度 ([c5650ac](https://review.byted.org/#/q/c5650ac)), closes [#920103965688335](https://jira.bytedance.com/browse/LKI-920103965688335)
* **voip:** voip新增打点。 ([5a730b5](https://review.byted.org/#/q/5a730b5)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **voip:** 对端响应时间修改为系统时间 ([0dfcdb7](https://review.byted.org/#/q/0dfcdb7)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **voip:** 异常打点 ([73d254e](https://review.byted.org/#/q/73d254e)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **voip:** 更改打点参数名称 ([cfdb051](https://review.byted.org/#/q/cfdb051)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **voip:** 更新sdk版本、去掉没必要的上报打点。 ([e4b80e9](https://review.byted.org/#/q/e4b80e9)), closes [#0](https://jira.bytedance.com/browse/LKI-0)


### Features

* **byteview:** slardar打点支持 ([61ace6a](https://review.byted.org/#/q/61ace6a)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **byteview:** 更新ByteView到0.3.29 ([977bef3](https://review.byted.org/#/q/977bef3)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **byteview:** 更新ByteView到0.3.30，修改参数名"duration" -> "client_duration" ([132ec00](https://review.byted.org/#/q/132ec00)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **byteview:** 更新至0.3.28版本，新增技术监控和业务埋点 ([8cc5278](https://review.byted.org/#/q/8cc5278)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **calendar:** 设置页添加日历设置 ([ce5e63b](https://review.byted.org/#/q/ce5e63b))
* **chat:** 【视频消息】iOS端使用新的FG key：video.enable.ios.v117 ([2787844](https://review.byted.org/#/q/2787844)), closes [#3191](https://jira.bytedance.com/browse/LKI-3191)
* **chat:** 1.抽出updateChatExtraInfo方法 2.去掉屏蔽分组/索引todo 3.chat页chatter刷新逻辑完善 4.去除ChatChattersInfo结构 ([ac4d763](https://review.byted.org/#/q/ac4d763)), closes [#3043](https://jira.bytedance.com/browse/LKI-3043)
* **chat:** chat 新增 ‘click_titlebar’埋点 ([ea2a5d6](https://review.byted.org/#/q/ea2a5d6)), closes [#3331](https://jira.bytedance.com/browse/LKI-3331)
* **chat:** chatNaviBar支持closeButton ([e59693f](https://review.byted.org/#/q/e59693f)), closes [#3201](https://jira.bytedance.com/browse/LKI-3201)
* **chat:** chatNaviBar支持展示多行 ([73cba75](https://review.byted.org/#/q/73cba75)), closes [#3169](https://jira.bytedance.com/browse/LKI-3169)
* **chat:** 修改群主转让姓名显示策略 ([fef5825](https://review.byted.org/#/q/fef5825)), closes [#3043](https://jira.bytedance.com/browse/LKI-3043)
* **chat:** 值班号群内特化 ([080fc91](https://review.byted.org/#/q/080fc91)), closes [#3195](https://jira.bytedance.com/browse/LKI-3195)
* **chat:** 单聊窗口顶部人名下方加一行签名 ([bb84059](https://review.byted.org/#/q/bb84059)), closes [#3169](https://jira.bytedance.com/browse/LKI-3169)
* **chat:** 单聊窗口顶部人名下方加一行签名, 支持富文本、可点击、调整Title位置、边距 ([45d32e7](https://review.byted.org/#/q/45d32e7)), closes [#3169](https://jira.bytedance.com/browse/LKI-3169)
* **chat:** 密聊群文案及群设置界面选项调整 ([3f37ff6](https://review.byted.org/#/q/3f37ff6)), closes [#3242](https://jira.bytedance.com/browse/LKI-3242)
* **chat:** 对接message isBadged属性，保证新消息线正确显示 ([97ae49c](https://review.byted.org/#/q/97ae49c)), closes [#2964](https://jira.bytedance.com/browse/LKI-2964)
* **chat:** 群设置页加群昵称修改入口 ([70ff125](https://review.byted.org/#/q/70ff125)), closes [#3164](https://jira.bytedance.com/browse/LKI-3164)
* **chat:** 解决单聊chatter可能取不到的问题 ([d49b9a1](https://review.byted.org/#/q/d49b9a1)), closes [#3043](https://jira.bytedance.com/browse/LKI-3043)
* **component:**  Lark 支持拍视频：修复视频可能保存失败 ([96f0a2e](https://review.byted.org/#/q/96f0a2e)), closes [#3284](https://jira.bytedance.com/browse/LKI-3284)
* **component:** Lark dev 使用独立的 deviceID 和 installID ([90b3fb8](https://review.byted.org/#/q/90b3fb8)), closes [#3289](https://jira.bytedance.com/browse/LKI-3289)
* **component:** 启用‘short.video.ios.v118’ 控制新旧相机的切换 ([7f977ee](https://review.byted.org/#/q/7f977ee)), closes [#3316](https://jira.bytedance.com/browse/LKI-3316)
* **component:** 姓名长度、空格校验 ([cf01b43](https://review.byted.org/#/q/cf01b43)), closes [#3243](https://jira.bytedance.com/browse/LKI-3243)
* **component:** 更新EEMicroAppSDK版本，修复小程序引擎相关bugfix ([a5e5de1](https://review.byted.org/#/q/a5e5de1))
* **component:** 标签样式优化 ([f6f0faa](https://review.byted.org/#/q/f6f0faa)), closes [#3198](https://jira.bytedance.com/browse/LKI-3198)
* **component:** 标签样式优化，登录页面 ([5621a87](https://review.byted.org/#/q/5621a87)), closes [#3198](https://jira.bytedance.com/browse/LKI-3198)
* **contact:** departmentViewModel接入pushChatter ([c318ad2](https://review.byted.org/#/q/c318ad2)), closes [#3190](https://jira.bytedance.com/browse/LKI-3190)
* **contact:** 创建群打点需求 ([4ca90ab](https://review.byted.org/#/q/4ca90ab)), closes [#2977](https://jira.bytedance.com/browse/LKI-2977)
* **contact:** 完成forwardViewController UI ([015f339](https://review.byted.org/#/q/015f339)), closes [#3307](https://jira.bytedance.com/browse/LKI-3307)
* **contact:** 日历添加人员，默认不选择自己 ([048ba09](https://review.byted.org/#/q/048ba09)), closes [#3194](https://jira.bytedance.com/browse/LKI-3194)
* **contact:** 添加personcard 动画 ([e3da873](https://review.byted.org/#/q/e3da873)), closes [#3295](https://jira.bytedance.com/browse/LKI-3295)
* **contact:** 添加刷新动画以及选择逻辑 ([4be440f](https://review.byted.org/#/q/4be440f)), closes [#3307](https://jira.bytedance.com/browse/LKI-3307)
* **contact:** 添加搜索接口 ([e8306b0](https://review.byted.org/#/q/e8306b0)), closes [#3192](https://jira.bytedance.com/browse/LKI-3192)
* **contact:** 重构personcard UI ([b9d5167](https://review.byted.org/#/q/b9d5167)), closes [#3295](https://jira.bytedance.com/browse/LKI-3295)
* **docs:** fix web comment bugs ([f0cc9bc](https://review.byted.org/#/q/f0cc9bc))
* **feed:** FeedSyncDispatchService 增加获取所有的置顶会话 ([6091fd7](https://review.byted.org/#/q/6091fd7)), closes [#3307](https://jira.bytedance.com/browse/LKI-3307)
* **feed:** Feed列表显示值班号群的图标 ([12d376f](https://review.byted.org/#/q/12d376f)), closes [#3196](https://jira.bytedance.com/browse/LKI-3196)
* **feed:** 在稍后处理列表done掉一个会话时，同时将这个会话标记为“已处理” ([30f08e4](https://review.byted.org/#/q/30f08e4)), closes [#3090](https://jira.bytedance.com/browse/LKI-3090)
* **finance:** 修复一些小问题 ([256477b](https://review.byted.org/#/q/256477b)), closes [#2955](https://jira.bytedance.com/browse/LKI-2955)
* **finance:** 修复红包一些 UI 问题 ([e281300](https://review.byted.org/#/q/e281300)), closes [#3237](https://jira.bytedance.com/browse/LKI-3237)
* **finance:** 修复红包系统消息点击不准的问题 ([50f9da2](https://review.byted.org/#/q/50f9da2)), closes [#3315](https://jira.bytedance.com/browse/LKI-3315)
* **finance:** 和安卓同学对了一遍，梳理领红包流程 ([ee7a03a](https://review.byted.org/#/q/ee7a03a)), closes [#2955](https://jira.bytedance.com/browse/LKI-2955)
* **finance:** 开红包界面，金币转动至少1.4s ([911a78d](https://review.byted.org/#/q/911a78d)), closes [#2960](https://jira.bytedance.com/browse/LKI-2960)
* **finance:** 开红包界面动画速度调整 ([cbdbc3e](https://review.byted.org/#/q/cbdbc3e)), closes [#2960](https://jira.bytedance.com/browse/LKI-2960)
* **finance:** 抢红包请求error处理 ([44ad369](https://review.byted.org/#/q/44ad369)), closes [#2961](https://jira.bytedance.com/browse/LKI-2961)
* **finance:** 接入财经 SDK ([aa2b8b3](https://review.byted.org/#/q/aa2b8b3)), closes [#2959](https://jira.bytedance.com/browse/LKI-2959)
* **finance:** 接入财经 SDK ([52c2abd](https://review.byted.org/#/q/52c2abd)), closes [#2959](https://jira.bytedance.com/browse/LKI-2959)
* **finance:** 红包相关请求加上log ([5fe16f6](https://review.byted.org/#/q/5fe16f6)), closes [#2955](https://jira.bytedance.com/browse/LKI-2955)
* **finance:** 红包系统消息可点击 ([32e5bc3](https://review.byted.org/#/q/32e5bc3)), closes [#3283](https://jira.bytedance.com/browse/LKI-3283)
* **finance:** 解决钱包页面会一直loading的问题 ([9ff8b7a](https://review.byted.org/#/q/9ff8b7a)), closes [#2965](https://jira.bytedance.com/browse/LKI-2965)
* **finance:** 钱包区分环境 ([0954c1d](https://review.byted.org/#/q/0954c1d)), closes [#3293](https://jira.bytedance.com/browse/LKI-3293)
* **finance:** 钱包帮助页面支持中英文切换 ([e7dd055](https://review.byted.org/#/q/e7dd055)), closes [#2965](https://jira.bytedance.com/browse/LKI-2965)
* **finance:** 钱包页面UI走查问题修改 ([b659eae](https://review.byted.org/#/q/b659eae)), closes [#2965](https://jira.bytedance.com/browse/LKI-2965)
* **login:** 扫码登录验证页ui根据服务器配置显示 ([d324830](https://review.byted.org/#/q/d324830)), closes [#3218](https://jira.bytedance.com/browse/LKI-3218)
* **message:** (1) 加入chatChatterDataFetcher (2)加入getChatChatter接口 (3)对接quasimsg的fromChatter ([7b89f70](https://review.byted.org/#/q/7b89f70)), closes [#3043](https://jira.bytedance.com/browse/LKI-3043)
* **message:** chatChatter对接调整 ([eca509a](https://review.byted.org/#/q/eca509a)), closes [#3197](https://jira.bytedance.com/browse/LKI-3197)
* **message:** chatvc支持不可见消息逻辑 ([ed3c628](https://review.byted.org/#/q/ed3c628)), closes [#2964](https://jira.bytedance.com/browse/LKI-2964)
* **message:** Lark支持拍摄视频 ([a8ae9ff](https://review.byted.org/#/q/a8ae9ff)), closes [#3284](https://jira.bytedance.com/browse/LKI-3284)
* **message:** message 新增 doc url 打点 ([12da2a6](https://review.byted.org/#/q/12da2a6)), closes [#3156](https://jira.bytedance.com/browse/LKI-3156)
* **message:** Post消息隐藏“无标题帖子”的文案 ([73f4dec](https://review.byted.org/#/q/73f4dec)), closes [#3216](https://jira.bytedance.com/browse/LKI-3216)
* **message:** 修复正常标题的帖子不显示标题问题 ([5a7d4e7](https://review.byted.org/#/q/5a7d4e7)), closes [#3216](https://jira.bytedance.com/browse/LKI-3216)
* **message:** 合并转发/收藏title显示调整 ([c9f7f39](https://review.byted.org/#/q/c9f7f39)), closes [#3309](https://jira.bytedance.com/browse/LKI-3309)
* **message:** 增加+1/抱拳两个表情 ([77560c1](https://review.byted.org/#/q/77560c1)), closes [#3181](https://jira.bytedance.com/browse/LKI-3181)
* **message:** 撤回消息，加急卡片也要消失 ([e543d6b](https://review.byted.org/#/q/e543d6b)), closes [#3312](https://jira.bytedance.com/browse/LKI-3312)
* **message:** 消息折叠展开 ([cfa5643](https://review.byted.org/#/q/cfa5643)), closes [#3298](https://jira.bytedance.com/browse/LKI-3298)
* **message:** 消息撤回重新编辑 ([600d455](https://review.byted.org/#/q/600d455)), closes [#3143](https://jira.bytedance.com/browse/LKI-3143)
* **message:** 适配详情页nickName ([54c0b9b](https://review.byted.org/#/q/54c0b9b)), closes [#3163](https://jira.bytedance.com/browse/LKI-3163)
* **microapp:** 小程序路由支持打开另外一个小程序的功能 ([f3e7793](https://review.byted.org/#/q/f3e7793)), closes [#3319](https://jira.bytedance.com/browse/LKI-3319)
* **mine:** 添加时间戳处理方法 ([355d823](https://review.byted.org/#/q/355d823)), closes [#3102](https://jira.bytedance.com/browse/LKI-3102)
* **search:** 增加一个hybridSearch接口（本地，网络搜索混合） ([5388032](https://review.byted.org/#/q/5388032)), closes [#3189](https://jira.bytedance.com/browse/LKI-3189)
* **search:** 搜索体验优化 ([a3ff2a9](https://review.byted.org/#/q/a3ff2a9)), closes [#3336](https://jira.bytedance.com/browse/LKI-3336) [#3338](https://jira.bytedance.com/browse/LKI-3338)
* **search:** 搜索加埋点 ([908cacb](https://review.byted.org/#/q/908cacb)), closes [#3157](https://jira.bytedance.com/browse/LKI-3157)
* **search:** 搜索加埋点 ([51c4bde](https://review.byted.org/#/q/51c4bde)), closes [#3157](https://jira.bytedance.com/browse/LKI-3157)
* **search:** 搜索各个页面去掉throttle ([31c3c5c](https://review.byted.org/#/q/31c3c5c)), closes [#3188](https://jira.bytedance.com/browse/LKI-3188)
* **search:** 搜索接入本地搜索 ([c2dbb5d](https://review.byted.org/#/q/c2dbb5d)), closes [#3189](https://jira.bytedance.com/browse/LKI-3189)
* **search:** 搜索添加featureGating ([584430c](https://review.byted.org/#/q/584430c)), closes [#3313](https://jira.bytedance.com/browse/LKI-3313)
* **search:** 搜索添加值班号 ([3b02875](https://review.byted.org/#/q/3b02875)), closes [#3317](https://jira.bytedance.com/browse/LKI-3317)
* **search:** 搜索结果按照排序展示，而不是展示先回来的结果 ([e717a6d](https://review.byted.org/#/q/e717a6d)), closes [#3344](https://jira.bytedance.com/browse/LKI-3344)
* **search:** 搜索请求拆分 ([bb03fff](https://review.byted.org/#/q/bb03fff)), closes [#3265](https://jira.bytedance.com/browse/LKI-3265)
* **search:** 搜索页面增加转场动画 ([4571f84](https://review.byted.org/#/q/4571f84)), closes [#3278](https://jira.bytedance.com/browse/LKI-3278)
* **search:** 本地搜索支持分页请求 ([aedcdd6](https://review.byted.org/#/q/aedcdd6)), closes [#3187](https://jira.bytedance.com/browse/LKI-3187)
* **search:** 添加搜索oncall icon ([67d5a84](https://review.byted.org/#/q/67d5a84)), closes [#3192](https://jira.bytedance.com/browse/LKI-3192)
* **VoIP:** PushKit推送到达时打点 ([edcda70](https://review.byted.org/#/q/edcda70))
* **web:** 扫一扫支持本地相册 ([d415d2b](https://review.byted.org/#/q/d415d2b)), closes [#3168](https://jira.bytedance.com/browse/LKI-3168)
* **web:** 更新AI-lab库，加入检测到疑似二维码，自动放大功能 ([0c8f9dc](https://review.byted.org/#/q/0c8f9dc)), closes [#2934](https://jira.bytedance.com/browse/LKI-2934)
* add more tests ([53e126c](https://review.byted.org/#/q/53e126c))
* Calendar 1.17.2 ([731287b](https://review.byted.org/#/q/731287b))
* docsView auto scroll ([94b9c9b](https://review.byted.org/#/q/94b9c9b))
* Slardar打点简单封装 ([c872611](https://review.byted.org/#/q/c872611))


### Performance Improvements

* **feed:** 双月体验优化-对话右滑关闭误触问题 ([0aaeb70](https://review.byted.org/#/q/0aaeb70)), closes [#3274](https://jira.bytedance.com/browse/LKI-3274)



<a name="1.16.1"></a>
## 1.16.1 (2018-11-13)


### Bug Fixes

* **chat:** 解决会议系统消息后紧跟着的消息没有头像的问题 ([79c3dec](https://review.byted.org/#/q/79c3dec)), closes [#3173](https://jira.bytedance.com/browse/LKI-3173)
* **component:** 日志上传丢失文件 ([d638b29](https://review.byted.org/#/q/d638b29)), closes [#3176](https://jira.bytedance.com/browse/LKI-3176)
* **docs:** 从feed进入文档点击分享会出现卡死的情况 ([e97411f](https://review.byted.org/#/q/e97411f))


### Features

* **chat:** chat页对接pushnickname ([fa1d797](https://review.byted.org/#/q/fa1d797)), closes [#3177](https://jira.bytedance.com/browse/LKI-3177)
* **chat:** 对接chatter chatExtraInfo属性，对接MGetChattersRequest chatId属性 ([72f3593](https://review.byted.org/#/q/72f3593)), closes [#3174](https://jira.bytedance.com/browse/LKI-3174)
* **chat:** 群设置页加群昵称修改入口, 添加 FeatureGating， 接Push ([faf8d81](https://review.byted.org/#/q/faf8d81)), closes [#3164](https://jira.bytedance.com/browse/LKI-3164) [#3165](https://jira.bytedance.com/browse/LKI-3165)
* **contact:** 添加oncall联系人相关逻辑及页面 ([13fcf05](https://review.byted.org/#/q/13fcf05)), closes [#3175](https://jira.bytedance.com/browse/LKI-3175)
* **contact:** 添加备注名fg ([c799314](https://review.byted.org/#/q/c799314)), closes [#3166](https://jira.bytedance.com/browse/LKI-3166)
* **message:** 备注名/群昵称修改补漏 ([b622c07](https://review.byted.org/#/q/b622c07)), closes [#3171](https://jira.bytedance.com/browse/LKI-3171)



<a name="1.16.0"></a>
# 1.16.0 (2018-11-12)


### Bug Fixes

* **byteview:** 修复Zoom Crash ([aba3b4d](https://review.byted.org/#/q/aba3b4d)), closes [#3123](https://jira.bytedance.com/browse/LKI-3123)
* **calendar:** 修复日历new角标、docs FG问题 ([b3ff25a](https://review.byted.org/#/q/b3ff25a))
* **calendar:** 日程详情跳转不了URL ([c4ce990](https://review.byted.org/#/q/c4ce990))
* **chat:** 【会话消息】点击消息时间显示不出来 ([b0247d4](https://review.byted.org/#/q/b0247d4)), closes [#3128](https://jira.bytedance.com/browse/LKI-3128)
* **chat:** chatvc点击视频 队列被锁死 ([41d8758](https://review.byted.org/#/q/41d8758)), closes [#3121](https://jira.bytedance.com/browse/LKI-3121)
* **chat:** chat页特化机器人不应该显示bot标签 ([8a4ecf3](https://review.byted.org/#/q/8a4ecf3)), closes [#3122](https://jira.bytedance.com/browse/LKI-3122)
* **chat:** chat页面，键盘弹起后，边缘回退后取消不退出页面，键盘盖住了消息 ([4fa9869](https://review.byted.org/#/q/4fa9869)), closes [#3088](https://jira.bytedance.com/browse/LKI-3088)
* **chat:** chat页面下拉加载更早消息，已读状态更新错误问题 ([4936510](https://review.byted.org/#/q/4936510)), closes [#3127](https://jira.bytedance.com/browse/LKI-3127)
* **chat:** 修复通过菜单点赞、回复错乱问题. ([ffee590](https://review.byted.org/#/q/ffee590)), closes [#3061](https://jira.bytedance.com/browse/LKI-3061)
* **chat:** 修正 DraftCacheImpl unowned to weak ([11b6b0a](https://review.byted.org/#/q/11b6b0a)), closes [#3139](https://jira.bytedance.com/browse/LKI-3139)
* **chat:** 修正chatvm pushChat更新逻辑问题(https://review.byted.org/#/c/ee/lark/ios-client/+/714462/) ([b10ba94](https://review.byted.org/#/q/b10ba94)), closes [#3120](https://jira.bytedance.com/browse/LKI-3120)
* **chat:** 修正点赞/查看视频/查看帖子手势与查看时间行为互相影响的问题 ([8e61868](https://review.byted.org/#/q/8e61868)), closes [#3146](https://jira.bytedance.com/browse/LKI-3146)
* **chat:** 看长消息详情/帖子导致chat页面锁死 ([575c515](https://review.byted.org/#/q/575c515)), closes [#3138](https://jira.bytedance.com/browse/LKI-3138)
* **chat:** 视频消息覆盖安装重发失败 ([fe02205](https://review.byted.org/#/q/fe02205)), closes [#3092](https://jira.bytedance.com/browse/LKI-3092)
* **chat:** 群聊设置页面所有设置失效 ([ffd1124](https://review.byted.org/#/q/ffd1124)), closes [#3113](https://jira.bytedance.com/browse/LKI-3113)
* **chat:** 解散群组提示“你已不在群聊”,优化离群Push依赖 ([31faa55](https://review.byted.org/#/q/31faa55)), closes [#3142](https://jira.bytedance.com/browse/LKI-3142)
* **component:** 【视频消息】保存到相册过程中，左上角✘点击无效 ([5a55da2](https://review.byted.org/#/q/5a55da2)), closes [#3125](https://jira.bytedance.com/browse/LKI-3125)
* **component:** 头条圈评论框交互优化 ([00677dc](https://review.byted.org/#/q/00677dc))
* **component:** 调整日志打包逻辑 ([f0980ae](https://review.byted.org/#/q/f0980ae)), closes [#3141](https://jira.bytedance.com/browse/LKI-3141)
* **contact:** 修复外部联系人拉取重复 ([0c56302](https://review.byted.org/#/q/0c56302)), closes [#3106](https://jira.bytedance.com/browse/LKI-3106)
* **contact:** 修改邀请好友键盘样式 ([f9c0a3a](https://review.byted.org/#/q/f9c0a3a)), closes [#3062](https://jira.bytedance.com/browse/LKI-3062)
* **docs:** Docs tab的页面内切换崩溃 ([2160f6c](https://review.byted.org/#/q/2160f6c)), closes [#3107](https://jira.bytedance.com/browse/LKI-3107)
* **docs:** export long pic & feed's loading error ([5c66df3](https://review.byted.org/#/q/5c66df3))
* **docs:** export pic & feed comment bugs ([76562cc](https://review.byted.org/#/q/76562cc))
* **docs:** LB bug in docs feed module, export picture function bug fix ([e0702e7](https://review.byted.org/#/q/e0702e7))
* **docs:** show comment card when keyboard showing ([1500aa8](https://review.byted.org/#/q/1500aa8))
* **docs:** 卡片评论被键盘遮挡 ([0becf9a](https://review.byted.org/#/q/0becf9a))
* **feed:** FeedPreview 增加日志定位 Feed 不刷新的问题 ([4986771](https://review.byted.org/#/q/4986771)), closes [#3105](https://jira.bytedance.com/browse/LKI-3105)
* 修复小程序中打开Doc后返回小程序导航栏异常问题 ([37fce21](https://review.byted.org/#/q/37fce21))
* **feed:** 过滤器对接 NavigatorNotification ([e290eda](https://review.byted.org/#/q/e290eda)), closes [#3048](https://jira.bytedance.com/browse/LKI-3048)
* fix docs cannot get auth info result in crash ([c85638b](https://review.byted.org/#/q/c85638b))
* **setting:** 国际化文案优化,  修改和替换部分文案. ([2a9df43](https://review.byted.org/#/q/2a9df43)), closes [#3076](https://jira.bytedance.com/browse/LKI-3076)
* 更新EEMicroAppSDK组件，修复UI交互相关问题 ([c843d42](https://review.byted.org/#/q/c843d42))
* **mail:** 邮件上下挪动抄送人时，手势冲突&层级问题 ([36c47df](https://review.byted.org/#/q/36c47df)), closes [#3017](https://jira.bytedance.com/browse/LKI-3017)
* **message:** 修复LKLabel问题 && 行高自行计算修改以适应视觉效果 ([303f83d](https://review.byted.org/#/q/303f83d)), closes [#3100](https://jira.bytedance.com/browse/LKI-3100)
* **message:** 直接点击点赞图标，没有刷新，队列没有放开 ([4318ec1](https://review.byted.org/#/q/4318ec1)), closes [#3104](https://jira.bytedance.com/browse/LKI-3104)
* **mine:** 修复个人联系人由于同步请求造成首次安装获取数据不正确 ([64255fc](https://review.byted.org/#/q/64255fc)), closes [#3097](https://jira.bytedance.com/browse/LKI-3097)
* **search:** 修复搜索feedback丢失逻辑 ([7b4c981](https://review.byted.org/#/q/7b4c981)), closes [#3077](https://jira.bytedance.com/browse/LKI-3077)
* **search:** 进入会话历史页侧边栏的搜索后立马切换tab不成功/跳转到一般被卡住(iPhoneX) ([86f0141](https://review.byted.org/#/q/86f0141)), closes [#3006](https://jira.bytedance.com/browse/LKI-3006)
* **voip:** 修复打点无效问题 ([fb9988c](https://review.byted.org/#/q/fb9988c)), closes [#2975](https://jira.bytedance.com/browse/LKI-2975)
* **web:** 扫码结束后没有弹出登录授权页面 ([c286746](https://review.byted.org/#/q/c286746)), closes [#3099](https://jira.bytedance.com/browse/LKI-3099)


### Features

* **byteview:** 屏幕常亮，最小化响铃消失 ([493d30c](https://review.byted.org/#/q/493d30c)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **chat:** 【视频消息】下载进度条优化 ([bb09232](https://review.byted.org/#/q/bb09232)), closes [#2717](https://jira.bytedance.com/browse/LKI-2717)
* **chat:** at选择人列表页面/输入框中@/对接群昵称/备注名 ([8c3d56e](https://review.byted.org/#/q/8c3d56e)), closes [#3056](https://jira.bytedance.com/browse/LKI-3056)
* **chat:** chat页titleBar支持点击进设置页 ([d431b73](https://review.byted.org/#/q/d431b73)), closes [#3130](https://jira.bytedance.com/browse/LKI-3130)
* **chat:** 上气泡逻辑支持noBadgeCount消息计数 ([170f694](https://review.byted.org/#/q/170f694)), closes [#3089](https://jira.bytedance.com/browse/LKI-3089)
* **chat:** 优化多选转发交互 ([f3eab69](https://review.byted.org/#/q/f3eab69)), closes [#3085](https://jira.bytedance.com/browse/LKI-3085)
* **chat:** 单聊/机器人聊天窗口去掉姓名和状态. ([c7242a3](https://review.byted.org/#/q/c7242a3)), closes [#3053](https://jira.bytedance.com/browse/LKI-3053)
* **chat:** 单聊窗口姓名优化, 机器人聊天页顶部增加 icon. ([978b1c6](https://review.byted.org/#/q/978b1c6)), closes [#3053](https://jira.bytedance.com/browse/LKI-3053)
* **chat:** 当群内只有一个人时，点击退出群组则直接退出，不提示转让群主的页面 ([87515cc](https://review.byted.org/#/q/87515cc)), closes [#3117](https://jira.bytedance.com/browse/LKI-3117)
* **chat:** 撤回消息重新编辑，UI & FeatureGating ([2fa68b8](https://review.byted.org/#/q/2fa68b8)), closes [#3144](https://jira.bytedance.com/browse/LKI-3144)
* **chat:** 群相关界面对接群昵称/备注名逻辑 ([c4d4cbc](https://review.byted.org/#/q/c4d4cbc)), closes [#3064](https://jira.bytedance.com/browse/LKI-3064)
* **chat:** 自己的会话去掉已读未读状态显示. ([44bb75f](https://review.byted.org/#/q/44bb75f)), closes [#3046](https://jira.bytedance.com/browse/LKI-3046)
* **component:** chatvc中输入框/pin/收藏列表/回复对接用户名称逻辑 ([a25346b](https://review.byted.org/#/q/a25346b)), closes [#3055](https://jira.bytedance.com/browse/LKI-3055)
* **component:** 手机号支持复制操作 ([1995bc7](https://review.byted.org/#/q/1995bc7)), closes [#3152](https://jira.bytedance.com/browse/LKI-3152)
* **component:** 支持自定义 staging feature id ([ae6b9f3](https://review.byted.org/#/q/ae6b9f3)), closes [#3075](https://jira.bytedance.com/browse/LKI-3075)
* **component:** 添加 Heimdallr 上传 dsym 脚本 ([9cd0192](https://review.byted.org/#/q/9cd0192)), closes [#3074](https://jira.bytedance.com/browse/LKI-3074)
* **component:** 请求版本信息添加新的字段 ([625d90c](https://review.byted.org/#/q/625d90c)), closes [#3078](https://jira.bytedance.com/browse/LKI-3078)
* **contact:** 对接备注名字段，完成群成员服务类 ([50fbaf3](https://review.byted.org/#/q/50fbaf3)), closes [#3044](https://jira.bytedance.com/browse/LKI-3044)
* **contact:** 开放密聊 ([6ff3ca9](https://review.byted.org/#/q/6ff3ca9)), closes [#3158](https://jira.bytedance.com/browse/LKI-3158)
* **contact:** 接入设置备注API ([f052cf2](https://review.byted.org/#/q/f052cf2)), closes [#3067](https://jira.bytedance.com/browse/LKI-3067)
* **contact:** 添加personCardGroupRequest ([84a642b](https://review.byted.org/#/q/84a642b)), closes [#3058](https://jira.bytedance.com/browse/LKI-3058)
* **contact:** 添加workStatus，接入相应API至Mine和personcard ([f752fb3](https://review.byted.org/#/q/f752fb3)), closes [#3093](https://jira.bytedance.com/browse/LKI-3093)
* **contact:** 添加个人名片页相应cell ([0695105](https://review.byted.org/#/q/0695105)), closes [#3057](https://jira.bytedance.com/browse/LKI-3057)
* **contact:** 添加个人请假标签 ([4b772fc](https://review.byted.org/#/q/4b772fc)), closes [#3102](https://jira.bytedance.com/browse/LKI-3102)
* **contact:** 添加通讯录备注 ([2090e20](https://review.byted.org/#/q/2090e20)), closes [#3054](https://jira.bytedance.com/browse/LKI-3054)
* **docs:** Docs预览图片从top开始显示 ([7c97237](https://review.byted.org/#/q/7c97237)), closes [#3149](https://jira.bytedance.com/browse/LKI-3149)
* **email:** 处理邮件大图片转PNG造成内存过大问题 ([656c761](https://review.byted.org/#/q/656c761)), closes [#2559](https://jira.bytedance.com/browse/LKI-2559)
* **email:** 邮件模块支持路由 ([51b7822](https://review.byted.org/#/q/51b7822)), closes [#3101](https://jira.bytedance.com/browse/LKI-3101)
* **feed:** feedNaviBar点击时间增加throttle ([16464db](https://review.byted.org/#/q/16464db)), closes [#3160](https://jira.bytedance.com/browse/LKI-3160)
* **finance:**  更新RustPB, 红包结果页支持上拉加载更多 ([e3e4d9a](https://review.byted.org/#/q/e3e4d9a)), closes [#2961](https://jira.bytedance.com/browse/LKI-2961)
* **finance:**  钱包页面埋点 ([ad03adf](https://review.byted.org/#/q/ad03adf)), closes [#3070](https://jira.bytedance.com/browse/LKI-3070)
* **finance:**  钱包页面埋点 ([c4edaff](https://review.byted.org/#/q/c4edaff)), closes [#3071](https://jira.bytedance.com/browse/LKI-3071)
* **finance:** 修复红包cell显示不出来的问题 ([9269b98](https://review.byted.org/#/q/9269b98)), closes [#2955](https://jira.bytedance.com/browse/LKI-2955)
* **finance:** 创建LarkFinance模块 ([e9b7643](https://review.byted.org/#/q/e9b7643)), closes [#2955](https://jira.bytedance.com/browse/LKI-2955)
* **finance:** 发红包页面 ([0bff0d2](https://review.byted.org/#/q/0bff0d2)), closes [#2957](https://jira.bytedance.com/browse/LKI-2957)
* **finance:** 发红包页面支持转换红包类型 ([dc469b9](https://review.byted.org/#/q/dc469b9)), closes [#2957](https://jira.bytedance.com/browse/LKI-2957)
* **finance:** 发送红包接口 ([5d87a19](https://review.byted.org/#/q/5d87a19)), closes [#2957](https://jira.bytedance.com/browse/LKI-2957)
* **finance:** 和安卓，Rust同学沟通，完善各种抢红包逻辑 ([128b032](https://review.byted.org/#/q/128b032)), closes [#2961](https://jira.bytedance.com/browse/LKI-2961)
* **finance:** 增加抢红包，更新红包点击状态请求。 红包结果页面增加没有抢到金额的样式 ([7941a29](https://review.byted.org/#/q/7941a29)), closes [#2961](https://jira.bytedance.com/browse/LKI-2961)
* **finance:** 增加钱包入口 ([71760b3](https://review.byted.org/#/q/71760b3)), closes [#2965](https://jira.bytedance.com/browse/LKI-2965)
* **finance:** 开红包界面 ([743cafa](https://review.byted.org/#/q/743cafa)), closes [#2960](https://jira.bytedance.com/browse/LKI-2960)
* **finance:** 开红包界面request, reponse创建 ([6bedb8c](https://review.byted.org/#/q/6bedb8c)), closes [#2960](https://jira.bytedance.com/browse/LKI-2960)
* **finance:** 开红包结果页面UI搭建 ([cda20a7](https://review.byted.org/#/q/cda20a7)), closes [#2961](https://jira.bytedance.com/browse/LKI-2961)
* **finance:** 开红包转场动画 ([cfeed05](https://review.byted.org/#/q/cfeed05)), closes [#2961](https://jira.bytedance.com/browse/LKI-2961)
* **finance:** 开红包页面展示，消失动画 ([1045b68](https://review.byted.org/#/q/1045b68)), closes [#2960](https://jira.bytedance.com/browse/LKI-2960)
* **finance:** 接入发红包界面 ([f7f6705](https://review.byted.org/#/q/f7f6705)), closes [#2958](https://jira.bytedance.com/browse/LKI-2958)
* **finance:** 更新RustPB，红包请求对接staging ([313614e](https://review.byted.org/#/q/313614e)), closes [#2955](https://jira.bytedance.com/browse/LKI-2955)
* **finance:** 更新红包PB ([3ba71d4](https://review.byted.org/#/q/3ba71d4)), closes [#2955](https://jira.bytedance.com/browse/LKI-2955)
* **finance:** 添加红包cell ([3c9154b](https://review.byted.org/#/q/3c9154b)), closes [#3083](https://jira.bytedance.com/browse/LKI-3083)
* **finance:** 红包各个页面接入真实数据结构，以及接入路由 ([9e1f879](https://review.byted.org/#/q/9e1f879)), closes [#2961](https://jira.bytedance.com/browse/LKI-2961)
* **finance:** 红包系统消息 ([4ae7848](https://review.byted.org/#/q/4ae7848)), closes [#2957](https://jira.bytedance.com/browse/LKI-2957)
* **finance:** 钱包界面开发 ([5a68490](https://review.byted.org/#/q/5a68490)), closes [#2966](https://jira.bytedance.com/browse/LKI-2966)
* **finance:** 钱包页面UI修改 ([87cfd22](https://review.byted.org/#/q/87cfd22)), closes [#2957](https://jira.bytedance.com/browse/LKI-2957)
* **forward:** 合并转发打点 ([d101b32](https://review.byted.org/#/q/d101b32)), closes [#3155](https://jira.bytedance.com/browse/LKI-3155)
* **LarkTracer:**  打点跟据环境设置参数避免staging,dev也被打到线上去 ([51fa8a2](https://review.byted.org/#/q/51fa8a2)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **message:** chatvc中reaction\头像处\长按头像，名称显示策略对接 ([0161575](https://review.byted.org/#/q/0161575)), closes [#3050](https://jira.bytedance.com/browse/LKI-3050)
* **message:** 加急选择页面对接群昵称/备注名 ([4075e82](https://review.byted.org/#/q/4075e82)), closes [#3060](https://jira.bytedance.com/browse/LKI-3060)
* **message:** 对接chatExtraInfo,将显示策略封装为类方法 ([6208743](https://review.byted.org/#/q/6208743)), closes [#3153](https://jira.bytedance.com/browse/LKI-3153)
* **message:** 用chatter的display扩展方法替换chatNickNameService ([0d03e28](https://review.byted.org/#/q/0d03e28)), closes [#3154](https://jira.bytedance.com/browse/LKI-3154)
* xunique Lark.xcodeproj ([6b4dec8](https://review.byted.org/#/q/6b4dec8)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **mine:** 增加 workDay 引导页. ([039a973](https://review.byted.org/#/q/039a973)), closes [#3061](https://jira.bytedance.com/browse/LKI-3061)
* **voip:** 添加 voip 埋点 ([ea8546b](https://review.byted.org/#/q/ea8546b)), closes [#3072](https://jira.bytedance.com/browse/LKI-3072)
* **web:**  对接AI-Lab扫码库 ([2a61715](https://review.byted.org/#/q/2a61715)), closes [#3038](https://jira.bytedance.com/browse/LKI-3038)
* **web:** webview升级，兼容WkWebview、UIWebview ([bde21e2](https://review.byted.org/#/q/bde21e2)), closes [#3068](https://jira.bytedance.com/browse/LKI-3068)


### Performance Improvements

* **feed:** 优化 iOS 调用 triggerSyncData 逻辑 ([5bb32a4](https://review.byted.org/#/q/5bb32a4)), closes [#3119](https://jira.bytedance.com/browse/LKI-3119)



<a name="1.15.0"></a>
# 1.15.0 (2018-10-29)


### Bug Fixes

* **byteview:** 主叫拨打被叫，被叫Lark未启动时没有响铃 ([086e894](https://review.byted.org/#/q/086e894)), closes [#3021](https://jira.bytedance.com/browse/LKI-3021)
* **byteview:** 修复视频会议入口偶尔显示不出来 ([7d3f6a1](https://review.byted.org/#/q/7d3f6a1)), closes [#3000](https://jira.bytedance.com/browse/LKI-3000)
* 修复webView白屏恢复打点;增加JSBridge性能分析打点;调整domReady打点位置; ([c98bdb0](https://review.byted.org/#/q/c98bdb0))
* **byteview:** 修改视频会议气泡文案 ([0743505](https://review.byted.org/#/q/0743505)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **byteview:** 增加断线气泡类型，进入会议统计入口 ([c45afd2](https://review.byted.org/#/q/c45afd2)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **byteview:** 群组会议按钮点击无反应，群组会议崩溃 ([396bbce](https://review.byted.org/#/q/396bbce)), closes [#3012](https://jira.bytedance.com/browse/LKI-3012) [#3013](https://jira.bytedance.com/browse/LKI-3013)
* **chat:** pin 模块试行自动国际化方案. ([8390e0b](https://review.byted.org/#/q/8390e0b)), closes [#3034](https://jira.bytedance.com/browse/LKI-3034)
* **chat:** 中文名视频发送后无法播放 ([a6ac950](https://review.byted.org/#/q/a6ac950)), closes [#2991](https://jira.bytedance.com/browse/LKI-2991)
* **chat:** 修复当 chatter localizedName 为空时, cell 气泡上移的问题. ([93e33cd](https://review.byted.org/#/q/93e33cd)), closes [#2882](https://jira.bytedance.com/browse/LKI-2882)
* **chat:** 视频消息要增加最小宽高的尺寸展示 ([c85b400](https://review.byted.org/#/q/c85b400)), closes [#2936](https://jira.bytedance.com/browse/LKI-2936)
* **chat:** 解决侧边栏提示约束冲突 ([ec27861](https://review.byted.org/#/q/ec27861)), closes [#2983](https://jira.bytedance.com/browse/LKI-2983)
* **component:** IOS端内滑动开关前端不显示转菊花 ([8eee46e](https://review.byted.org/#/q/8eee46e)), closes [#2973](https://jira.bytedance.com/browse/LKI-2973)
* **component:** 修复webView白屏恢复逻辑 ([61e9e84](https://review.byted.org/#/q/61e9e84))
* **component:** 拍照成功无法正常使用照片 ([ab143b3](https://review.byted.org/#/q/ab143b3)), closes [#2994](https://jira.bytedance.com/browse/LKI-2994)
* **component:** 超小视频压缩失败 ([ccebeac](https://review.byted.org/#/q/ccebeac)), closes [#3009](https://jira.bytedance.com/browse/LKI-3009)
* **contact:** 修复无法接受好友邀请的bug ([82d188f](https://review.byted.org/#/q/82d188f)), closes [#3025](https://jira.bytedance.com/browse/LKI-3025)
* **docs:** iOS12下分块渲染导致内容缺失 ([4e7d94e](https://review.byted.org/#/q/4e7d94e))
* **docs:** iOS12下分块渲染导致内容缺失 ([93455ff](https://review.byted.org/#/q/93455ff))
* **docs:** 前端埋点不上报 ([065318a](https://review.byted.org/#/q/065318a))
* **docs:** 多租户切换标识符错乱 ([64e4cda](https://review.byted.org/#/q/64e4cda))
* **dynamic:** dynamic regular font bugfix ([a20005a](https://review.byted.org/#/q/a20005a)), closes [#3023](https://jira.bytedance.com/browse/LKI-3023)
* **EEMicroAppSDK:** 小程序引擎framework支持i386架构 ([78afb6a](https://review.byted.org/#/q/78afb6a))
* **email:** 发送邮件页面无法收起键盘问题 ([057ecc7](https://review.byted.org/#/q/057ecc7)), closes [#3042](https://jira.bytedance.com/browse/LKI-3042)
* **feed:** 上跟rust商量的新的拉取Feed的策略 ([623f763](https://review.byted.org/#/q/623f763)), closes [#3014](https://jira.bytedance.com/browse/LKI-3014)
* **feed:** 稍后处理icon替换，头像badge视觉修正 ([64b4613](https://review.byted.org/#/q/64b4613)), closes [#2988](https://jira.bytedance.com/browse/LKI-2988)
* **feed:** 稍后处理列表navibar忘加显示badge ([7c07f5a](https://review.byted.org/#/q/7c07f5a)), closes [#2971](https://jira.bytedance.com/browse/LKI-2971)
* **file:** lark支持打开.key .number, .pages ([bd4600f](https://review.byted.org/#/q/bd4600f)), closes [#3033](https://jira.bytedance.com/browse/LKI-3033)
* **message:** chat页面内显示时间可能导致崩溃 ([2a7b3ef](https://review.byted.org/#/q/2a7b3ef)), closes [#3022](https://jira.bytedance.com/browse/LKI-3022)
* **message:** 临时修改多选时某些消息选不中的问题, 下一个版本重构checkbox逻辑. ([8c89909](https://review.byted.org/#/q/8c89909)), closes [#3003](https://jira.bytedance.com/browse/LKI-3003)
* **message:** 会话内跳转时锁队列，防止高亮可能过早结束 ([3b084dd](https://review.byted.org/#/q/3b084dd)), closes [#2972](https://jira.bytedance.com/browse/LKI-2972)
* **message:** 修复加急/非加急消息, 先变成全部已读再变成未读的问题. ([4192b42](https://review.byted.org/#/q/4192b42)), closes [#3005](https://jira.bytedance.com/browse/LKI-3005)
* **message:** 修复发消息可能导致的消息不上屏问题 ([7501541](https://review.byted.org/#/q/7501541)), closes [#3016](https://jira.bytedance.com/browse/LKI-3016)
* **message:** 修复详情页菜单无法点击的问题 ([085988d](https://review.byted.org/#/q/085988d)), closes [#2998](https://jira.bytedance.com/browse/LKI-2998)
* **message:** 修复语音气泡复用后, 长度不正确的问题. ([73392ed](https://review.byted.org/#/q/73392ed)), closes [#2952](https://jira.bytedance.com/browse/LKI-2952)
* **message:** 合并转发、收藏中的图片长按干掉跳转至会话 ([8926a37](https://review.byted.org/#/q/8926a37)), closes [#3011](https://jira.bytedance.com/browse/LKI-3011)
* **message:** 合并转发详情页对接表情预览 ([801828a](https://review.byted.org/#/q/801828a)), closes [#3008](https://jira.bytedance.com/browse/LKI-3008)
* **message:** 增加日志: 不该显示 showMore 时 LKLabel 返回 showMore=true. ([3208286](https://review.byted.org/#/q/3208286)), closes [#2854](https://jira.bytedance.com/browse/LKI-2854)
* **message:** 多选收藏语音cache问题 ([88f09bb](https://review.byted.org/#/q/88f09bb)), closes [#3018](https://jira.bytedance.com/browse/LKI-3018)
* **message:** 更新LKUIKit ([ffe1153](https://review.byted.org/#/q/ffe1153)), closes [#3032](https://jira.bytedance.com/browse/LKI-3032)
* **message:** 视频消息展示超小预览图时拉伸, 调整最小尺寸. ([cd5dad7](https://review.byted.org/#/q/cd5dad7)), closes [#2993](https://jira.bytedance.com/browse/LKI-2993)
* **message:** 绿点问题 && publish H5 Protos修改 && fg支持新的key ([6428d71](https://review.byted.org/#/q/6428d71)), closes [#2940](https://jira.bytedance.com/browse/LKI-2940)
* **message:** 解决feed未同步完提前进入会话，没有气泡及footer提示 ([98714a0](https://review.byted.org/#/q/98714a0)), closes [#3026](https://jira.bytedance.com/browse/LKI-3026)
* **message:** 解决消息不足一屏时，键盘弹出可能遮挡消息问题 ([1ce2c97](https://review.byted.org/#/q/1ce2c97)), closes [#2954](https://jira.bytedance.com/browse/LKI-2954)
* **search:** 文档超长时，会话内doc列表，跳转到会话按钮不显示 ([710d1f3](https://review.byted.org/#/q/710d1f3)), closes [#3030](https://jira.bytedance.com/browse/LKI-3030)
* **voip:** 修复恢复voip全屏时未收起键盘的问题 ([69093b8](https://review.byted.org/#/q/69093b8)), closes [#3040](https://jira.bytedance.com/browse/LKI-3040)
* **voip:** 重复拨打电话报错 ([72799b4](https://review.byted.org/#/q/72799b4)), closes [#2987](https://jira.bytedance.com/browse/LKI-2987)
* docs database carsh ([dcbeece](https://review.byted.org/#/q/dcbeece))
* 修复打开头条圈闪白屏的问题 ([98176c9](https://review.byted.org/#/q/98176c9))
* 小程序引擎日志脱敏，移除引擎setData和invoke对敏感信息的log ([3c12fa3](https://review.byted.org/#/q/3c12fa3))


### Features

* **feed:** 增加稍后处理统一入口 ([acdbdcc](https://review.byted.org/#/q/acdbdcc)), closes [#2971](https://jira.bytedance.com/browse/LKI-2971)
* add access info in info.plist ([274022e](https://review.byted.org/#/q/274022e))
* **byteview:** 优化1v1流程、灰度自研sdk ([b9e55d8](https://review.byted.org/#/q/b9e55d8)), closes [#2222](https://jira.bytedance.com/browse/LKI-2222)
* **chat:** 【视频消息】压缩与转码 ([e7fab7f](https://review.byted.org/#/q/e7fab7f)), closes [#2771](https://jira.bytedance.com/browse/LKI-2771)
* **component:** 会话设置	新增埋点 ([1ec667c](https://review.byted.org/#/q/1ec667c)), closes [#2978](https://jira.bytedance.com/browse/LKI-2978)
* **component:** 完成chatter对接国际化姓名 ([ae3e867](https://review.byted.org/#/q/ae3e867)), closes [#2953](https://jira.bytedance.com/browse/LKI-2953)
* **component:** 对接EELoginUserInfo的localizedName ([a691d47](https://review.byted.org/#/q/a691d47)), closes [#2953](https://jira.bytedance.com/browse/LKI-2953)
* **component:** 建群新增埋点 ([7c1f681](https://review.byted.org/#/q/7c1f681)), closes [#2976](https://jira.bytedance.com/browse/LKI-2976)
* **component:** 替换打点加密库 ([0191629](https://review.byted.org/#/q/0191629)), closes [#3039](https://jira.bytedance.com/browse/LKI-3039)
* **component:** 设置忽略icloud同步 ([fed7d54](https://review.byted.org/#/q/fed7d54)), closes [#2876](https://jira.bytedance.com/browse/LKI-2876)
* **contact:** 1.displayname替换为localizedName 2.本地索引排序使用sortIndexName ([885cd15](https://review.byted.org/#/q/885cd15)), closes [#2953](https://jira.bytedance.com/browse/LKI-2953)
* **contact:** 添加mineMainvc请假标签 ([000a240](https://review.byted.org/#/q/000a240)), closes [#3049](https://jira.bytedance.com/browse/LKI-3049)
* **contact:** 添加personCard的请假UILabel ([5f1257e](https://review.byted.org/#/q/5f1257e)), closes [#3045](https://jira.bytedance.com/browse/LKI-3045)
* **contact:** 通讯录leader对接localizeName ([dcc818c](https://review.byted.org/#/q/dcc818c)), closes [#3019](https://jira.bytedance.com/browse/LKI-3019)
* **feed:** 稍后处理List入口新增埋点 ([0ae500b](https://review.byted.org/#/q/0ae500b)), closes [#2984](https://jira.bytedance.com/browse/LKI-2984)
* **feed:** 统计会话盒子会话数量的埋点 ([095b111](https://review.byted.org/#/q/095b111)), closes [#2981](https://jira.bytedance.com/browse/LKI-2981)
* **message:**  去除视频发送、播放、下载的流量提示 ([325c453](https://review.byted.org/#/q/325c453)), closes [#2771](https://jira.bytedance.com/browse/LKI-2771)
* **message:** video消息详情页完善加载中 ([b542448](https://review.byted.org/#/q/b542448)), closes [#2771](https://jira.bytedance.com/browse/LKI-2771)
* **message:** 新增多选操作 ([e58e786](https://review.byted.org/#/q/e58e786)), closes [#2834](https://jira.bytedance.com/browse/LKI-2834)
* **mine:**  添加MineSetting的WorkdayCell UI ([50787d8](https://review.byted.org/#/q/50787d8)), closes [#3037](https://jira.bytedance.com/browse/LKI-3037)
* **search:** 外部文档旁边增加【外部】标签 ([8c7b8a3](https://review.byted.org/#/q/8c7b8a3)), closes [#2938](https://jira.bytedance.com/browse/LKI-2938)
* **voip:** 新的 VoIP UI 支持悬浮框 ([46367c2](https://review.byted.org/#/q/46367c2)), closes [#2752](https://jira.bytedance.com/browse/LKI-2752)
* authorization info localization ([efb9f26](https://review.byted.org/#/q/efb9f26))



<a name="1.14.2"></a>
## 1.14.2 (2018-10-16)


### Bug Fixes

* **component:** Lark 加载动画Gif占用大量内存导致Crash ([926d38f](https://review.byted.org/#/q/926d38f)), closes [#2949](https://jira.bytedance.com/browse/LKI-2949)
* **search:** 修复doc外部标签不显示的bug ([94ae2aa](https://review.byted.org/#/q/94ae2aa)), closes [#2950](https://jira.bytedance.com/browse/LKI-2950)


### Features

* **feed:** 外部文档旁边增加【外部】标签，并同时放到“文档”“外部”过滤器分类中 ([c556baf](https://review.byted.org/#/q/c556baf)), closes [#2938](https://jira.bytedance.com/browse/LKI-2938)
* **search:** 搜索文档添加外部标签 ([4f52e59](https://review.byted.org/#/q/4f52e59)), closes [#2950](https://jira.bytedance.com/browse/LKI-2950)



<a name="1.14.1"></a>
## 1.14.1 (2018-10-15)



<a name="1.14.0"></a>
# 1.14.0 (2018-10-14)


### Bug Fixes

* **byteview:** popup对话框按钮没有国际化 ([f6c1792](https://review.byted.org/#/q/f6c1792)), closes [#2918](https://jira.bytedance.com/browse/LKI-2918)
* **byteview:** 修复alert view 失效的问题 ([7942b9f](https://review.byted.org/#/q/7942b9f)), closes [#857065711546280](https://jira.bytedance.com/browse/LKI-857065711546280)
* **byteview:** 修复alert view 失效的问题 ([488439d](https://review.byted.org/#/q/488439d)), closes [#857065711546280](https://jira.bytedance.com/browse/LKI-857065711546280)
* **byteview:** 气泡消息不显示已读未读状态 ([8ffe1b4](https://review.byted.org/#/q/8ffe1b4)), closes [#828036070995934](https://jira.bytedance.com/browse/LKI-828036070995934)
* **Calendar:** 日历bot卡片更新日程视图机制调整 ([85b12ec](https://review.byted.org/#/q/85b12ec)), closes [#LKR-565](https://jira.bytedance.com/browse/LKI-LKR-565)
* **Calendar:** 日历bot卡片更新日程视图机制调整 ([81f1665](https://review.byted.org/#/q/81f1665)), closes [#LKR-565](https://jira.bytedance.com/browse/LKI-LKR-565)
* **chat:** 侧边栏和输入框不能同时出现. ([cf34016](https://review.byted.org/#/q/cf34016)), closes [#2905](https://jira.bytedance.com/browse/LKI-2905)
* **chat:** 修复 pin 列表刷新跳动的问题, 增加 un-pin 二次确认. ([dd98fe5](https://review.byted.org/#/q/dd98fe5)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** 修复 pin 列表在 iOS10 上显示错乱的问题, 优化代码结构. ([c24f3c4](https://review.byted.org/#/q/c24f3c4)), closes [#2865](https://jira.bytedance.com/browse/LKI-2865)
* **chat:** 修复 Pin 功能走查部分 UI 问题. ([3a57e04](https://review.byted.org/#/q/3a57e04)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** 修复 pin 走查的问题. ([ab90b77](https://review.byted.org/#/q/ab90b77)), closes [#2882](https://jira.bytedance.com/browse/LKI-2882)
* **chat:** 修复： ([867c4fb](https://review.byted.org/#/q/867c4fb)), closes [#2899](https://jira.bytedance.com/browse/LKI-2899)
* **chat:** 修复：设置页面群信息显示小二维码，添加是否可分享的判断 ([9b7fbc3](https://review.byted.org/#/q/9b7fbc3)), closes [#2899](https://jira.bytedance.com/browse/LKI-2899)
* **chat:** 修复侧边栏走查问题. ([f3cd9ff](https://review.byted.org/#/q/f3cd9ff)), closes [#2873](https://jira.bytedance.com/browse/LKI-2873)
* **chat:** 修复导航动画约束冲突以及添加好友内存泄漏 ([02a4ccf](https://review.byted.org/#/q/02a4ccf)), closes [#2904](https://jira.bytedance.com/browse/LKI-2904)
* **chat:** 修改导航图片,修改邀请电话输入键盘样式 ([df5c3ee](https://review.byted.org/#/q/df5c3ee)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** 截图发送给lark时，接收人姓名国际化 ([2635bfe](https://review.byted.org/#/q/2635bfe)), closes [#2915](https://jira.bytedance.com/browse/LKI-2915)
* **component:** Lark.iOS.XCode10打包加载Gif失败 ([97602f7](https://review.byted.org/#/q/97602f7)), closes [#2878](https://jira.bytedance.com/browse/LKI-2878)
* **component:** 扫码登录导致tab异常 ([d511611](https://review.byted.org/#/q/d511611)), closes [#2876](https://jira.bytedance.com/browse/LKI-2876)
* **component:** 解决staging环境下rust日志没被上传的问题 ([c6e97c8](https://review.byted.org/#/q/c6e97c8)), closes [#2870](https://jira.bytedance.com/browse/LKI-2870)
* **component:** 进入favorite详情奔溃 ([521c5a7](https://review.byted.org/#/q/521c5a7)), closes [#2875](https://jira.bytedance.com/browse/LKI-2875)
* **contact:** B端无法选取联系人创建群组 ([4af2ba6](https://review.byted.org/#/q/4af2ba6)), closes [#2871](https://jira.bytedance.com/browse/LKI-2871)
* **contact:** C端添加群成员搜索时添加失败 ([850ce31](https://review.byted.org/#/q/850ce31)), closes [#2894](https://jira.bytedance.com/browse/LKI-2894)
* **contact:** 修复namelabel被挤压的问题 ([97f255a](https://review.byted.org/#/q/97f255a)), closes [#2947](https://jira.bytedance.com/browse/LKI-2947)
* **contact:** 修复拉取不到chatapplication，添加pre-release环境 ([603f2f1](https://review.byted.org/#/q/603f2f1)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 修复搜索群组外部标签丢失 ([85bbf9d](https://review.byted.org/#/q/85bbf9d)), closes [#2939](https://jira.bytedance.com/browse/LKI-2939)
* **contact:** 修复断网情况下personCard显示不正确 ([c515074](https://review.byted.org/#/q/c515074)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 修复群主无法退出外部群bug ([bd9ffae](https://review.byted.org/#/q/bd9ffae)), closes [#2893](https://jira.bytedance.com/browse/LKI-2893)
* **contact:** 修复联系人设置第一次显示不正确 ([b0ece71](https://review.byted.org/#/q/b0ece71)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 修复自己的个人名片页显示不正确的bug ([96d41f5](https://review.byted.org/#/q/96d41f5)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 修改申请按钮文案 ([afa5892](https://review.byted.org/#/q/afa5892)), closes [#2925](https://jira.bytedance.com/browse/LKI-2925)
* **contact:** 修改邀请键盘return方法 ([48628ee](https://review.byted.org/#/q/48628ee)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 屏蔽外部群设置分享设置 ([813c35f](https://review.byted.org/#/q/813c35f)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 添加sideBar引导页国际化图片 ([926aad4](https://review.byted.org/#/q/926aad4)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **docs:** 修复返回文档会触发打开一篇新文档的bug ([0e56918](https://review.byted.org/#/q/0e56918))
* **feed:** done掉在一屏的临界点会话时，UI会有较大抖动 ([6ca991e](https://review.byted.org/#/q/6ca991e)), closes [#2836](https://jira.bytedance.com/browse/LKI-2836)
* **feed:** 修复tab双击失败问题 ([32d6e93](https://review.byted.org/#/q/32d6e93)), closes [#2863](https://jira.bytedance.com/browse/LKI-2863)
* **feed:** 盒子数据第一次从 offset=0 开始拉取 ([81fda75](https://review.byted.org/#/q/81fda75)), closes [#2923](https://jira.bytedance.com/browse/LKI-2923)
* **LB:** docs 无法发送评论 ([4d91d5d](https://review.byted.org/#/q/4d91d5d))
* **message:** 1.解决第一次发消息已读未读提示丢失问题 2.chamsgvm细分出消息发送中/成功两个信号 ([ee4b6ce](https://review.byted.org/#/q/ee4b6ce)), closes [#2849](https://jira.bytedance.com/browse/LKI-2849)
* **message:** at后输入输入法表情会导致乱码 ([287aeea](https://review.byted.org/#/q/287aeea)), closes [#2881](https://jira.bytedance.com/browse/LKI-2881)
* **message:** 主搜索入口搜消息定位时亮两次 ([51ed9bf](https://review.byted.org/#/q/51ed9bf)), closes [#2932](https://jira.bytedance.com/browse/LKI-2932)
* **message:** 修复合并转发消息发送失败的UI ([7f503d1](https://review.byted.org/#/q/7f503d1)), closes [#2284](https://jira.bytedance.com/browse/LKI-2284)
* **message:** 修复详情页菜单超出屏幕问题 ([62ab292](https://review.byted.org/#/q/62ab292)), closes [#2906](https://jira.bytedance.com/browse/LKI-2906)
* **message:** 群设置内的开关颜色修正 ([f3f2bb7](https://review.byted.org/#/q/f3f2bb7)), closes [#2866](https://jira.bytedance.com/browse/LKI-2866)
* **message:** 解决chat对接路由时，shownormalback属性传反，导致左上角未读标数不显示的问题 ([0af663c](https://review.byted.org/#/q/0af663c)), closes [#2941](https://jira.bytedance.com/browse/LKI-2941)
* **message:** 解决chat进入下一级页面后键盘收起逻辑错误的问题 ([b124f04](https://review.byted.org/#/q/b124f04)), closes [#2885](https://jira.bytedance.com/browse/LKI-2885)
* **microapp-iOS-sdk:** 优化小程序webView白屏恢复逻辑 ([f6c286c](https://review.byted.org/#/q/f6c286c))
* **search:** 会话盒子搜索结果使用后端返回的名字 ([b95b6f0](https://review.byted.org/#/q/b95b6f0)), closes [#2890](https://jira.bytedance.com/browse/LKI-2890)
* **search:** 修正会话内搜索文档图标 ([b073258](https://review.byted.org/#/q/b073258)), closes [#2897](https://jira.bytedance.com/browse/LKI-2897)
* **search:** 搜索图片预览前/后浏览打点修正 ([bbe8fb3](https://review.byted.org/#/q/bbe8fb3)), closes [#2827](https://jira.bytedance.com/browse/LKI-2827)
* **search:** 解决消息定位到会话时，本屏内消息不高亮问题 ([dbebf92](https://review.byted.org/#/q/dbebf92)), closes [#2922](https://jira.bytedance.com/browse/LKI-2922)
* **voip:** 优化VoIP拉活后台启动速度 ([3c79b07](https://review.byted.org/#/q/3c79b07)), closes [#2921](https://jira.bytedance.com/browse/LKI-2921)
* **voip:** 修复 voip 自研SDK网络状态同步问题 ([e9e73b9](https://review.byted.org/#/q/e9e73b9)), closes [#2943](https://jira.bytedance.com/browse/LKI-2943)
* **web:** GetDeviceInfo && log change from zhaochen ([a2e102e](https://review.byted.org/#/q/a2e102e)), closes [#2880](https://jira.bytedance.com/browse/LKI-2880)
* **web:** 处理浏览器重定向错误 ([72dc0c1](https://review.byted.org/#/q/72dc0c1)), closes [#2919](https://jira.bytedance.com/browse/LKI-2919)
* **web:** 扫描界面可以缩放，调整焦距 ([08d9da6](https://review.byted.org/#/q/08d9da6)), closes [#2933](https://jira.bytedance.com/browse/LKI-2933)


### Features

* **message:** LarkChat ModelExtension CardContent title ([c9c16e6](https://review.byted.org/#/q/c9c16e6)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* calendar创建、分享、转发只能搜索到本租户以内的人 ([858ab97](https://review.byted.org/#/q/858ab97))
* **byteview:** 更新byteview 模块版本 ([82cb03c](https://review.byted.org/#/q/82cb03c)), closes [#776681452030778](https://jira.bytedance.com/browse/LKI-776681452030778)
* **calendar:** 会议对接侧边栏 ([e5b6998](https://review.byted.org/#/q/e5b6998))
* **chat:** larkModel Message 增加pin相关数据. ([e7ac229](https://review.byted.org/#/q/e7ac229)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** pin 列表支持删除操作. ([e124d41](https://review.byted.org/#/q/e124d41)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** sideBar引导页 ([88a6af9](https://review.byted.org/#/q/88a6af9)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** 优化pin 确认/取消二次弹窗, 去耦合, 采用 request 方式调用. ([9d56c34](https://review.byted.org/#/q/9d56c34)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** 侧边栏新增埋点. ([f7f06f7](https://review.byted.org/#/q/f7f06f7)), closes [#2860](https://jira.bytedance.com/browse/LKI-2860)
* **chat:** 增加 pin 相关埋点和 action 操作. ([a039153](https://review.byted.org/#/q/a039153)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** 对接 pin list 消息操作事件. ([f967aa4](https://review.byted.org/#/q/f967aa4)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** 对接 pin 列表中的消息事件, 优化展示 UI. ([1f02adc](https://review.byted.org/#/q/1f02adc)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** 对接侧边栏. ([e42d67b](https://review.byted.org/#/q/e42d67b)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** 替换 sidebar icon和修改部分文案. ([1b7ee8c](https://review.byted.org/#/q/1b7ee8c)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** 构建 Pin 列表基本架构. ([6deee8a](https://review.byted.org/#/q/6deee8a)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** 构建 pin 数据和 UI 样式. ([d70ccf2](https://review.byted.org/#/q/d70ccf2)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **chat:** 群二维，扫码进群 ([7b0c9be](https://review.byted.org/#/q/7b0c9be)), closes [#2753](https://jira.bytedance.com/browse/LKI-2753)
* **chat:** 群二维码  新增埋点 ([c2d1697](https://review.byted.org/#/q/c2d1697)), closes [#2858](https://jira.bytedance.com/browse/LKI-2858)
* **chat:** 群二维码 扫码展示页面 添加刷新逻辑 ([a9cdfe8](https://review.byted.org/#/q/a9cdfe8)), closes [#2753](https://jira.bytedance.com/browse/LKI-2753)
* **chat:** 群二维码 扫码展示页面处理 ([2ce7d78](https://review.byted.org/#/q/2ce7d78)), closes [#2753](https://jira.bytedance.com/browse/LKI-2753)
* **chat:** 群二维码识别 ([ce0913a](https://review.byted.org/#/q/ce0913a)), closes [#2753](https://jira.bytedance.com/browse/LKI-2753)
* **component:** 升级策略，新增 popup_plan=2 渲染策略 ([868c179](https://review.byted.org/#/q/868c179)), closes [#2914](https://jira.bytedance.com/browse/LKI-2914)
* **contact:** 修改转让群主逻辑 ([05ee82a](https://review.byted.org/#/q/05ee82a)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 去掉跨租户fg ([9ba888e](https://review.byted.org/#/q/9ba888e)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 增加toC打点 ([ddeb426](https://review.byted.org/#/q/ddeb426)), closes [#2861](https://jira.bytedance.com/browse/LKI-2861)
* **docs:** update Docs SDK & 修改日志模块 ([3444f18](https://review.byted.org/#/q/3444f18))
* **dynamic:** 视频会议卡片调整，卡片消息支持aspectRatio ([dbb857e](https://review.byted.org/#/q/dbb857e)), closes [#2877](https://jira.bytedance.com/browse/LKI-2877)
* **feed:** 屏蔽掉EMAIL_ROOT_DRAFT类型feed卡片的右滑done掉操作 ([9024aa3](https://review.byted.org/#/q/9024aa3)), closes [#2855](https://jira.bytedance.com/browse/LKI-2855)
* **message:** 会话内图片查看支持跳转到chat ([65b0fb6](https://review.byted.org/#/q/65b0fb6)), closes [#2851](https://jira.bytedance.com/browse/LKI-2851)
* **message:** 增加 Pin 消息确认/取消弹窗. ([8271bd1](https://review.byted.org/#/q/8271bd1)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **message:** 消息增加 pin 功能. ([ed6fd29](https://review.byted.org/#/q/ed6fd29)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **message:** 消息增加 pin 操作, 重构气泡底部视图. ([924af9b](https://review.byted.org/#/q/924af9b)), closes [#2748](https://jira.bytedance.com/browse/LKI-2748)
* **message:** 被 pin 的消息需要在详情页展示, xxx pin 了这条消息 ([3eff32f](https://review.byted.org/#/q/3eff32f)), closes [#2879](https://jira.bytedance.com/browse/LKI-2879)
* support local notification enter detail view ([9465779](https://review.byted.org/#/q/9465779))
* **mine:** 屏蔽c端用户部门信息，更换添加联系人设置文案 ([1c91fd2](https://review.byted.org/#/q/1c91fd2)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **search:** 会话盒子支持搜索 ([63f0fe0](https://review.byted.org/#/q/63f0fe0)), closes [#2862](https://jira.bytedance.com/browse/LKI-2862)



<a name="1.13.0"></a>
# 1.13.0 (2018-09-25)


### Bug Fixes

* **byteview:**  视频会议气泡发起人修改，文案修改。 ([1835d63](https://review.byted.org/#/q/1835d63)), closes [#826288222930511](https://jira.bytedance.com/browse/LKI-826288222930511)
* **byteview:** iOS单聊+号新增视频通话入口，过滤自己。 ([08247fb](https://review.byted.org/#/q/08247fb)), closes [#2768](https://jira.bytedance.com/browse/LKI-2768)
* **byteview:** 更新LarkUIKit，修复 错误信息太长，无法完整显示toast问题 ([06c9258](https://review.byted.org/#/q/06c9258)), closes [#819720780828029](https://jira.bytedance.com/browse/LKI-819720780828029)
* **Calendar:** 日历SDK加载时区文件Crash修复 ([c2004ba](https://review.byted.org/#/q/c2004ba))
* **chat:** 修复会话详情页面富文本编辑页面显示错误 ([82bab5d](https://review.byted.org/#/q/82bab5d)), closes [#2805](https://jira.bytedance.com/browse/LKI-2805)
* **chat:** 修复图片bundle错误 ([46784e5](https://review.byted.org/#/q/46784e5)), closes [#2848](https://jira.bytedance.com/browse/LKI-2848)
* **chat:** 单聊机器人添加到消息盒子会失败 ([e6fef3b](https://review.byted.org/#/q/e6fef3b)), closes [#2713](https://jira.bytedance.com/browse/LKI-2713)
* **chat:** 解决chat页面有时候naviBar位置错乱的问题 ([d2dba9e](https://review.byted.org/#/q/d2dba9e)), closes [#2837](https://jira.bytedance.com/browse/LKI-2837)
* **chat:** 语音播放 unowned崩溃 ([e194b48](https://review.byted.org/#/q/e194b48)), closes [#2843](https://jira.bytedance.com/browse/LKI-2843)
* **component:** 【视频消息】图片选择器提示与问题 ([6e6447b](https://review.byted.org/#/q/6e6447b)), closes [#2808](https://jira.bytedance.com/browse/LKI-2808)
* **component:** 修复 push handler 与 rust client 的循环引用 ([e5373b2](https://review.byted.org/#/q/e5373b2)), closes [#2832](https://jira.bytedance.com/browse/LKI-2832)
* **component:** 更新LarkTracker,解决category无法提交的问题 ([f3649e8](https://review.byted.org/#/q/f3649e8)), closes [#2749](https://jira.bytedance.com/browse/LKI-2749)
* **component:** 视频预览退出动画异常 ([0d97f4c](https://review.byted.org/#/q/0d97f4c)), closes [#2747](https://jira.bytedance.com/browse/LKI-2747)
* **component:** 适配Xcode10和iOS12 ([1533361](https://review.byted.org/#/q/1533361)), closes [#2814](https://jira.bytedance.com/browse/LKI-2814)
* **contact:** 修复push ExternalContacts没有chatter以及更新eelogin的版本 ([90a1e00](https://review.byted.org/#/q/90a1e00)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 修复个人名片页首次注册用户bug ([d4351b1](https://review.byted.org/#/q/d4351b1)), closes [#2823](https://jira.bytedance.com/browse/LKI-2823)
* **contact:** 修复外租户过滤器不屏蔽邮件 ([1b19fe2](https://review.byted.org/#/q/1b19fe2)), closes [#2751](https://jira.bytedance.com/browse/LKI-2751)
* **contact:** 修复外部联系人feed过滤器问题，添加刷新二维码HUD ([2bfd5e9](https://review.byted.org/#/q/2bfd5e9)), closes [#2795](https://jira.bytedance.com/browse/LKI-2795)
* **contact:** 修复外部联系人投票入口 ([24add46](https://review.byted.org/#/q/24add46)), closes [#2751](https://jira.bytedance.com/browse/LKI-2751)
* **contact:** 修复外部联系人标签不正确 ([6860747](https://review.byted.org/#/q/6860747)), closes [#2786](https://jira.bytedance.com/browse/LKI-2786)
* **contact:** 修复群添加联系人错误 ([a90448f](https://review.byted.org/#/q/a90448f)), closes [#2751](https://jira.bytedance.com/browse/LKI-2751)
* **contact:** 修复联系人页导航字体颜色，修复加好友跳转逻辑，邀请成功返回页面显示不正确 ([189129f](https://review.byted.org/#/q/189129f)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 修复邀请页面邀请成功后页面显示错乱bug ([55bc485](https://review.byted.org/#/q/55bc485)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 屏蔽视频跨租户入口 ([c517e5a](https://review.byted.org/#/q/c517e5a)), closes [#2751](https://jira.bytedance.com/browse/LKI-2751)
* **dynamic:** 点击Link跳转 ([c2ec445](https://review.byted.org/#/q/c2ec445)), closes [#2800](https://jira.bytedance.com/browse/LKI-2800)
* **EEMicroAppSDK:**  修复进入打卡小程序时不能弹起申请位置权限的问题 ([c05fb28](https://review.byted.org/#/q/c05fb28))
* **email:** 处理邮件刷新过于频繁的问题 ([7b5ff30](https://review.byted.org/#/q/7b5ff30)), closes [#2784](https://jira.bytedance.com/browse/LKI-2784)
* **favorite:** 修复已解散的群的收藏消息显示BUG ([a3afe53](https://review.byted.org/#/q/a3afe53)), closes [#2770](https://jira.bytedance.com/browse/LKI-2770)
* **feed:** feed中preview的颜色改为，at是蓝色，新消息是灰色，无未读是灰色 ([321ad46](https://review.byted.org/#/q/321ad46)), closes [#2817](https://jira.bytedance.com/browse/LKI-2817)
* **feed:** 会话盒子 Feed 改动联调 ([0215bd2](https://review.byted.org/#/q/0215bd2)), closes [#2825](https://jira.bytedance.com/browse/LKI-2825)
* **feed:** 修复外租户过滤器中有密聊选项 ([a2e5873](https://review.byted.org/#/q/a2e5873)), closes [#2835](https://jira.bytedance.com/browse/LKI-2835)
* **file:** 本地视频截图，增加缓存功能 ([15fb0e3](https://review.byted.org/#/q/15fb0e3)), closes [#2829](https://jira.bytedance.com/browse/LKI-2829)
* **LB:** [LKI-2802]进入过doc后，会议的手势返回会失效 ([e95cede](https://review.byted.org/#/q/e95cede))
* **LB:** Docs 上报数据全部缺失 ([97075a6](https://review.byted.org/#/q/97075a6))
* **LB:** open folder bug ([64a5610](https://review.byted.org/#/q/64a5610))
* **LB:** 修改 Docs 白屏和调试 Bug ([d27b8e7](https://review.byted.org/#/q/d27b8e7))
* **message:** SetImageMessage preload fail ([e6b6a57](https://review.byted.org/#/q/e6b6a57)), closes [#2809](https://jira.bytedance.com/browse/LKI-2809)
* **message:** SetImageMessage preload fail ([a7bb45b](https://review.byted.org/#/q/a7bb45b)), closes [#2809](https://jira.bytedance.com/browse/LKI-2809)
* **message:** 会话内连接重连后，离线消息上屏问题修复(NoticeClientEventRequest导致) ([4684416](https://review.byted.org/#/q/4684416)), closes [#2842](https://jira.bytedance.com/browse/LKI-2842)
* **message:** 修复发图编辑，发出去后没有保存的问题 ([61554f7](https://review.byted.org/#/q/61554f7)), closes [#2803](https://jira.bytedance.com/browse/LKI-2803)
* **message:** 修正点赞错乱问题 ([27d40e1](https://review.byted.org/#/q/27d40e1)), closes [#2773](https://jira.bytedance.com/browse/LKI-2773)
* **message:** 离职人员聊天页面水印在iphonex上透底 ([bc3320f](https://review.byted.org/#/q/bc3320f)), closes [#2712](https://jira.bytedance.com/browse/LKI-2712)
* **message:** 解决部分图片发不出去的问题 ([f610369](https://review.byted.org/#/q/f610369)), closes [#2818](https://jira.bytedance.com/browse/LKI-2818)
* **mine:** logoutCell触控区域小 ([dadade6](https://review.byted.org/#/q/dadade6)), closes [#2833](https://jira.bytedance.com/browse/LKI-2833)
* **mine:** 修复外租户logoutCellUI不正确 ([14c20fa](https://review.byted.org/#/q/14c20fa)), closes [#2801](https://jira.bytedance.com/browse/LKI-2801)
* **search:** 修复搜索历史复用问题 ([e2bcb17](https://review.byted.org/#/q/e2bcb17)), closes [#2779](https://jira.bytedance.com/browse/LKI-2779)
* **search:** 修复日程分享可以搜到外租户 ([c8bdde6](https://review.byted.org/#/q/c8bdde6)), closes [#2821](https://jira.bytedance.com/browse/LKI-2821)
* **search:** 处理老图的显示问题 ([d79aac2](https://review.byted.org/#/q/d79aac2)), closes [#2782](https://jira.bytedance.com/browse/LKI-2782)
* **search:** 搜索出来的会议要进入会议页面 ([5f9adc5](https://review.byted.org/#/q/5f9adc5))
* **voip:** 修复自研SDK解密失败问题 ([428d885](https://review.byted.org/#/q/428d885)), closes [#2799](https://jira.bytedance.com/browse/LKI-2799)


### Features

* **byteview:** 单聊工具键盘增加视频会议入口 ([38f8b01](https://review.byted.org/#/q/38f8b01)), closes [#2768](https://jira.bytedance.com/browse/LKI-2768)
* **byteview:** 视频会议优化 1. 人数限制动态调整 2. 卡片优化：loading 3. 移动端多人发起视频时使用流量提醒 4. 视频通话服务版本升级提醒 ([fc39391](https://review.byted.org/#/q/fc39391)), closes [#812766118153452](https://jira.bytedance.com/browse/LKI-812766118153452)
* **byteview:** 识别点击事件，并广播通知。目标完成需求：点击加入会议，展示HUD。 ([0f26cf1](https://review.byted.org/#/q/0f26cf1)), closes [#819720780828031](https://jira.bytedance.com/browse/LKI-819720780828031)
* **chat:** imagePicker增加埋点 ([58e049c](https://review.byted.org/#/q/58e049c)), closes [#2742](https://jira.bytedance.com/browse/LKI-2742)
* **chat:** 单聊Bot添加“添加到会话盒子”入口 ([9b9a16e](https://review.byted.org/#/q/9b9a16e)), closes [#2777](https://jira.bytedance.com/browse/LKI-2777)
* **chat:** 单聊Bot添加“添加到会话盒子”入口，调整UI细节，优化图片预览体验 ([8a6e149](https://review.byted.org/#/q/8a6e149)), closes [#2777](https://jira.bytedance.com/browse/LKI-2777)
* **chat:** 群二维码 ([27641a2](https://review.byted.org/#/q/27641a2)), closes [#2753](https://jira.bytedance.com/browse/LKI-2753)
* **chat:** 群二维码 添加拉取Token、Chat的接口 ([7bd0eeb](https://review.byted.org/#/q/7bd0eeb)), closes [#2753](https://jira.bytedance.com/browse/LKI-2753)
* **chat:** 群二维码、支持分享 ([3787133](https://review.byted.org/#/q/3787133)), closes [#2753](https://jira.bytedance.com/browse/LKI-2753)
* **chat:** 群二维码优化代码结构 ([d059f3e](https://review.byted.org/#/q/d059f3e)), closes [#2753](https://jira.bytedance.com/browse/LKI-2753)
* **chat:** 群设置添加“添加到会话盒子”入口 ([1e9a215](https://review.byted.org/#/q/1e9a215)), closes [#2777](https://jira.bytedance.com/browse/LKI-2777)
* **chat:** 聊天页面增加侧边栏. ([75defd3](https://review.byted.org/#/q/75defd3)), closes [#2740](https://jira.bytedance.com/browse/LKI-2740)
* **chat:** 聊天页面增加侧边栏选项. ([04affc6](https://review.byted.org/#/q/04affc6)), closes [#2740](https://jira.bytedance.com/browse/LKI-2740)
* **chat:** 非字节用户第一次使用密聊时，弹出风险提示弹层. ([982f30f](https://review.byted.org/#/q/982f30f)), closes [#2729](https://jira.bytedance.com/browse/LKI-2729)
* **component:**  删除DK相关，接入ImagePicker ([3753726](https://review.byted.org/#/q/3753726)), closes [#2742](https://jira.bytedance.com/browse/LKI-2742)
* **component:** 会话提醒打点 ([5d1832c](https://review.byted.org/#/q/5d1832c)), closes [#2761](https://jira.bytedance.com/browse/LKI-2761)
* **component:** 通用	新增埋点 ([bca3188](https://review.byted.org/#/q/bca3188)), closes [#2759](https://jira.bytedance.com/browse/LKI-2759)
* **component:** 针对toC用户，控制群标签显示 ([defe949](https://review.byted.org/#/q/defe949)), closes [#2714](https://jira.bytedance.com/browse/LKI-2714)
* **contact:**  修改邀请联系人featureGating ([4b601ff](https://review.byted.org/#/q/4b601ff)), closes [#2715](https://jira.bytedance.com/browse/LKI-2715)
* **contact:**  添加/邀请联系人页面搜索 ([efe6a5d](https://review.byted.org/#/q/efe6a5d)), closes [#2715](https://jira.bytedance.com/browse/LKI-2715)
* **contact:**  添加/邀请联系人页面搜索, 增加featureGating，增加搜索结果不存在页面 ([7f01b81](https://review.byted.org/#/q/7f01b81)), closes [#2715](https://jira.bytedance.com/browse/LKI-2715)
* **contact:** FloadActionVeiwController init方法中传入最小化依赖 ([dd2ed62](https://review.byted.org/#/q/dd2ed62)), closes [#2715](https://jira.bytedance.com/browse/LKI-2715)
* **contact:** to c 联系人列表视图 ([375128b](https://review.byted.org/#/q/375128b)), closes [#2709](https://jira.bytedance.com/browse/LKI-2709)
* **contact:** to c 联系人选择页面 ([a96d873](https://review.byted.org/#/q/a96d873)), closes [#2711](https://jira.bytedance.com/browse/LKI-2711)
* **contact:** 修复邀请逻辑 ([05aa7f4](https://review.byted.org/#/q/05aa7f4)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 修复邮件输入约束不正确 ([8b45a8e](https://review.byted.org/#/q/8b45a8e)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 修改个人名片c端判断同一公司逻辑 ([e19fefc](https://review.byted.org/#/q/e19fefc)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 修改判断customer方式 ([618c69b](https://review.byted.org/#/q/618c69b)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 修改联系人Cell样式， 修复登录激活bug ([4dcd572](https://review.byted.org/#/q/4dcd572)), closes [#2838](https://jira.bytedance.com/browse/LKI-2838)
* **contact:** 修改邀请进入个人名片页后pop页面 ([0f05677](https://review.byted.org/#/q/0f05677)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 增加chatApplication邀请接口 ([8a3b5ab](https://review.byted.org/#/q/8a3b5ab)), closes [#2750](https://jira.bytedance.com/browse/LKI-2750)
* **contact:** 添加invitationView及相关逻辑 ([8125947](https://review.byted.org/#/q/8125947)), closes [#2743](https://jira.bytedance.com/browse/LKI-2743)
* **contact:** 添加selectCountryNumberView ([c6e7aae](https://review.byted.org/#/q/c6e7aae)), closes [#2745](https://jira.bytedance.com/browse/LKI-2745)
* **contact:** 添加搜索跳转邀请逻辑 ([e20ebf5](https://review.byted.org/#/q/e20ebf5)), closes [#2830](https://jira.bytedance.com/browse/LKI-2830)
* **contact:** 添加格式不正确的错误 ([9f9e37a](https://review.byted.org/#/q/9f9e37a)), closes [#2750](https://jira.bytedance.com/browse/LKI-2750)
* **contact:** 添加激活流程 ([9fee0e7](https://review.byted.org/#/q/9fee0e7)), closes [#2680](https://jira.bytedance.com/browse/LKI-2680)
* **contact:** 添加联系人页面搭建 ([94e6f48](https://review.byted.org/#/q/94e6f48)), closes [#2715](https://jira.bytedance.com/browse/LKI-2715)
* **dynamic:** support TimeComponent ([d071aef](https://review.byted.org/#/q/d071aef)), closes [#2732](https://jira.bytedance.com/browse/LKI-2732)
* **dynamic:** update TimeComponent numberOfLines ([308ee68](https://review.byted.org/#/q/308ee68)), closes [#2732](https://jira.bytedance.com/browse/LKI-2732)
* **dynamic:** 卡片消息支持Link标签 && Action打开其他url ([7f9af3a](https://review.byted.org/#/q/7f9af3a)), closes [#2735](https://jira.bytedance.com/browse/LKI-2735)
* **dynamic:** 详情页Time Link处理，未知标签处理 ([8746e0b](https://review.byted.org/#/q/8746e0b)), closes [#2785](https://jira.bytedance.com/browse/LKI-2785)
* **EEMicroAppSDK:** 修复资源文件配置 ([ba97f2c](https://review.byted.org/#/q/ba97f2c))
* **feed:** 双击tab可定位到稍后处理的会话 ([97dbf36](https://review.byted.org/#/q/97dbf36)), closes [#2744](https://jira.bytedance.com/browse/LKI-2744)
* **feed:** 取消延后更名为“已处理/Resolved” ([6a354d3](https://review.byted.org/#/q/6a354d3)), closes [#2769](https://jira.bytedance.com/browse/LKI-2769)
* **feed:** 完成会话盒子 ([d78932d](https://review.byted.org/#/q/d78932d)), closes [#2767](https://jira.bytedance.com/browse/LKI-2767)
* **feed:** 消息盒子新增埋点 ([f8bb212](https://review.byted.org/#/q/f8bb212)), closes [#2767](https://jira.bytedance.com/browse/LKI-2767)
* **foundation:** GetDeviceId 接口增加参数 ([0e1589c](https://review.byted.org/#/q/0e1589c)), closes [#2706](https://jira.bytedance.com/browse/LKI-2706)
* **login:** 每次账号切换时updateDeviceInfo ([d09eff7](https://review.byted.org/#/q/d09eff7)), closes [#2778](https://jira.bytedance.com/browse/LKI-2778)
* **login:** 登陆邮箱&短信验证码&客服群名国际化 ([ae266a7](https://review.byted.org/#/q/ae266a7)), closes [#2772](https://jira.bytedance.com/browse/LKI-2772)
* **login:** 登陆邮箱&短信验证码&客服群名国际化 ([4c867d1](https://review.byted.org/#/q/4c867d1)), closes [#2772](https://jira.bytedance.com/browse/LKI-2772)
* **message:** 会话内查看图片打点 ([ce08464](https://review.byted.org/#/q/ce08464)), closes [#2766](https://jira.bytedance.com/browse/LKI-2766)
* **message:** 合并转发/部门群加打点 ([20ee3c6](https://review.byted.org/#/q/20ee3c6)), closes [#2765](https://jira.bytedance.com/browse/LKI-2765) [#2764](https://jira.bytedance.com/browse/LKI-2764)
* fix navigation bug, fix a loading bug when switch tab ([7938825](https://review.byted.org/#/q/7938825))
* **message:** 图片查看对接加载更多 ([224d63a](https://review.byted.org/#/q/224d63a)), closes [#2755](https://jira.bytedance.com/browse/LKI-2755)
* **message:** 图片查看支持跳转到会话 ([2022c6e](https://review.byted.org/#/q/2022c6e)), closes [#2780](https://jira.bytedance.com/browse/LKI-2780)
* **message:** 普通图片与post图统一浏览 ([6dbd73e](https://review.byted.org/#/q/6dbd73e)), closes [#2790](https://jira.bytedance.com/browse/LKI-2790)
* **message:** 添加视频消息缓存 ([5fdeab9](https://review.byted.org/#/q/5fdeab9)), closes [#2721](https://jira.bytedance.com/browse/LKI-2721)
* **resource:** 接入SDK进度条 ([1d37c6c](https://review.byted.org/#/q/1d37c6c)), closes [#2426](https://jira.bytedance.com/browse/LKI-2426)
* **search:** 1.会话内图片查看页面对接lkDisplayAssetVC已有逻辑 2.会话历史文案调整 ([5f8eaef](https://review.byted.org/#/q/5f8eaef)), closes [#2739](https://jira.bytedance.com/browse/LKI-2739) [#2758](https://jira.bytedance.com/browse/LKI-2758)
* **search:** 会话内图片查看页面ui实现 ([8c51d62](https://review.byted.org/#/q/8c51d62)), closes [#2734](https://jira.bytedance.com/browse/LKI-2734)
* **search:** 会话内图片查看页面框架基本搭建 ([2bcfd2a](https://review.byted.org/#/q/2bcfd2a)), closes [#2737](https://jira.bytedance.com/browse/LKI-2737)
* **search:** 会话内查看图片问题修改 1.ui调整 2.gif不自动播放 3.加载缩略图 ([2384c27](https://review.byted.org/#/q/2384c27)), closes [#2791](https://jira.bytedance.com/browse/LKI-2791)
* **voip:** 优化voip响铃以及震动规则，与微信保持一致 ([198f7ae](https://review.byted.org/#/q/198f7ae)), closes [#2707](https://jira.bytedance.com/browse/LKI-2707)
* **voip:** 修正计时开始时机 ([9128a0b](https://review.byted.org/#/q/9128a0b)), closes [#2746](https://jira.bytedance.com/browse/LKI-2746)
* [EEMicroAppSDK] support gray for js sdk and microApp ([ab5b9b1](https://review.byted.org/#/q/ab5b9b1))
* update docs sdk, refactor navigation bar, fix mutil users change bug ([5ab32c5](https://review.byted.org/#/q/5ab32c5))



<a name="1.12.1"></a>
## 1.12.1 (2018-09-10)


### Bug Fixes

* **byteview:** 1. 恢复会议Calling页面无法显示对方头像和名称,  2. 会中邀请和会前选人，默认自己可选。3. 搜索去除自己。 4. 添加性能监控 ([80c760b](https://review.byted.org/#/q/80c760b)), closes [#2702](https://jira.bytedance.com/browse/LKI-2702)
* **byteview:** update RxAutomaton  for issue ([4639230](https://review.byted.org/#/q/4639230)), closes [#2662](https://jira.bytedance.com/browse/LKI-2662)
* **byteview:** Zoom SDK中ZMZoomViewController会延迟释放，因此加入白名单避免内存泄漏的Alert ([76861e9](https://review.byted.org/#/q/76861e9)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **byteview:** 主叫忙线，没有toast提示 ([9a66a31](https://review.byted.org/#/q/9a66a31))
* **byteview:** 修复tracker 导致的crash ([76258f5](https://review.byted.org/#/q/76258f5)), closes [#807381026979106](https://jira.bytedance.com/browse/LKI-807381026979106)
* **byteview:** 更新版本 ([80a0bde](https://review.byted.org/#/q/80a0bde)), closes [#2662](https://jira.bytedance.com/browse/LKI-2662)
* **byteview:** 视频会议修复打点类型错误 ([46234c3](https://review.byted.org/#/q/46234c3))
* **byteview:** 移动端视频通话响铃页被输入键盘挡住 ([0dea05f](https://review.byted.org/#/q/0dea05f))
* **calendar:** 新建日程时，添加参与人但未保存时，组织者的名称不见了 ([5fb3616](https://review.byted.org/#/q/5fb3616)), closes [#2700](https://jira.bytedance.com/browse/LKI-2700)
* **calendar:** 日程分享,日程分享转发需要屏蔽 1. 密聊. 2.外部联系人. 3.外部群 ([e9ad11d](https://review.byted.org/#/q/e9ad11d)), closes [#2638](https://jira.bytedance.com/browse/LKI-2638)
* **calendar:** 进入会议聊天界面闪烁, 并导致草稿失效 ([c438f92](https://review.byted.org/#/q/c438f92)), closes [#2682](https://jira.bytedance.com/browse/LKI-2682)
* **chat:** 【视频消息】一系列FB ([523fe79](https://review.byted.org/#/q/523fe79)), closes [#2685](https://jira.bytedance.com/browse/LKI-2685)
* **chat:** 【视频消息】一系列FB: 视频播放忽略系统静音； 修复视频因为preview取不到发布出去的问题 ([eed4967](https://review.byted.org/#/q/eed4967)), closes [#2685](https://jira.bytedance.com/browse/LKI-2685)
* **chat:** 修复checkIsBurned crash ([5852fa3](https://review.byted.org/#/q/5852fa3)), closes [#2621](https://jira.bytedance.com/browse/LKI-2621)
* **chat:** 修复给Lark Team机器人转发消息失败时，feed中有叹号会话内没有的问题. ([022fa00](https://review.byted.org/#/q/022fa00)), closes [#2622](https://jira.bytedance.com/browse/LKI-2622)
* **chat:** 图片编辑增加打点 ([e06f402](https://review.byted.org/#/q/e06f402)), closes [#2635](https://jira.bytedance.com/browse/LKI-2635)
* **chat:** 群设置优化 ([badd27e](https://review.byted.org/#/q/badd27e)), closes [#2655](https://jira.bytedance.com/browse/LKI-2655)
* **chat:** 解决最后一条消息被删除时，无法定位到会话尾部的问题 ([b61c8f0](https://review.byted.org/#/q/b61c8f0)), closes [#2691](https://jira.bytedance.com/browse/LKI-2691)
* **chat:** 解决进入客服群崩溃问题 ([95a4ebf](https://review.byted.org/#/q/95a4ebf)), closes [#2697](https://jira.bytedance.com/browse/LKI-2697)
* **component:** 「我的」升级红点没有了 ([6e733df](https://review.byted.org/#/q/6e733df)), closes [#1](https://jira.bytedance.com/browse/LKI-1)
* **component:** draft 没有缓存存储数据问题 ([a788a52](https://review.byted.org/#/q/a788a52)), closes [#2673](https://jira.bytedance.com/browse/LKI-2673)
* **component:** setClientNetworkType时crash ([39717f8](https://review.byted.org/#/q/39717f8)), closes [#2651](https://jira.bytedance.com/browse/LKI-2651)
* **component:** 修复表情键盘未隐藏action btn 的BUG ([3eb848f](https://review.byted.org/#/q/3eb848f)), closes [#2606](https://jira.bytedance.com/browse/LKI-2606)
* **component:** 外部跳转到lark的请求校验是否登录 ([3d2188b](https://review.byted.org/#/q/3d2188b)), closes [#2648](https://jira.bytedance.com/browse/LKI-2648)
* **component:** 补全上传日志逻辑 ([a7b17b1](https://review.byted.org/#/q/a7b17b1)), closes [#2701](https://jira.bytedance.com/browse/LKI-2701)
* **component:** 解决photoScrollPicker在相册无照片情况下崩溃问题 ([dae31d6](https://review.byted.org/#/q/dae31d6)), closes [#2649](https://jira.bytedance.com/browse/LKI-2649)
* **contact:** 修复applicationButton显示不正确 ([bc64b9a](https://review.byted.org/#/q/bc64b9a)), closes [#2670](https://jira.bytedance.com/browse/LKI-2670)
* **contact:** 修复ContactBadge push无显示 ([251a592](https://review.byted.org/#/q/251a592)), closes [#2676](https://jira.bytedance.com/browse/LKI-2676)
* **contact:** 修复personCard闪蓝色按钮 ([d5e2a96](https://review.byted.org/#/q/d5e2a96)), closes [#2670](https://jira.bytedance.com/browse/LKI-2670)
* **contact:** 修复UI问题 ([4000632](https://review.byted.org/#/q/4000632)), closes [#2676](https://jira.bytedance.com/browse/LKI-2676)
* **contact:** 修复个人名片异步显示 ([6bf1238](https://review.byted.org/#/q/6bf1238)), closes [#2689](https://jira.bytedance.com/browse/LKI-2689)
* **contact:** 修复修改personCardRequest导致申请无法跳转个人名片页 ([93ce8b0](https://review.byted.org/#/q/93ce8b0)), closes [#2736](https://jira.bytedance.com/browse/LKI-2736)
* **contact:** 修复删除联系人不正确的问题 ([7490b22](https://review.byted.org/#/q/7490b22)), closes [#2696](https://jira.bytedance.com/browse/LKI-2696)
* **contact:** 修复无法同意好友申请 ([56dcec0](https://review.byted.org/#/q/56dcec0)), closes [#2675](https://jira.bytedance.com/browse/LKI-2675)
* **contact:** 修复点击已读未读头像crash的问题，清理personcard async请求 ([5b8bb06](https://review.byted.org/#/q/5b8bb06)), closes [#2704](https://jira.bytedance.com/browse/LKI-2704)
* **contact:** 修复邮箱无法显示，外部联系人格式不正确 ([ded7ae6](https://review.byted.org/#/q/ded7ae6)), closes [#2708](https://jira.bytedance.com/browse/LKI-2708)
* **contact:** 修改contact 头像有灰边 ([d2e4177](https://review.byted.org/#/q/d2e4177)), closes [#2694](https://jira.bytedance.com/browse/LKI-2694)
* **contact:** 文案修正/会话内离职遮罩布局调整 ([6951060](https://review.byted.org/#/q/6951060)), closes [#2668](https://jira.bytedance.com/browse/LKI-2668)
* **contact:** 解决一处departmentvc强转崩溃问题 ([652372b](https://review.byted.org/#/q/652372b)), closes [#2660](https://jira.bytedance.com/browse/LKI-2660)
* **contact:** 通讯录搜索框需要和新版首页的搜索框一致 ([2005803](https://review.byted.org/#/q/2005803)), closes [#2689](https://jira.bytedance.com/browse/LKI-2689)
* **docs:** Docs预览url被拉伸 ([4ce5d1a](https://review.byted.org/#/q/4ce5d1a)), closes [#2626](https://jira.bytedance.com/browse/LKI-2626)
* **Docs:** 上报埋点bug fix ([974947b](https://review.byted.org/#/q/974947b))
* **dynamic:** LarkDynamicView figure处理有问题\n ([ea1b6e6](https://review.byted.org/#/q/ea1b6e6)), closes [#2691](https://jira.bytedance.com/browse/LKI-2691)
* **dynamic:** 卡片消息底层view mask到背景图形状 ([005a922](https://review.byted.org/#/q/005a922)), closes [#2695](https://jira.bytedance.com/browse/LKI-2695)
* **EEMicroAppSDK:** 修复头条圈第二次点击上传图片没响应的问题 ([ceb71ce](https://review.byted.org/#/q/ceb71ce))
* **email:** 修复发送过长邮件页面变白问题 ([f70be66](https://review.byted.org/#/q/f70be66)), closes [#2640](https://jira.bytedance.com/browse/LKI-2640)
* **feed:** 修改FeedNaviBar产品走查的bug ([bde2a7c](https://review.byted.org/#/q/bde2a7c)), closes [#2613](https://jira.bytedance.com/browse/LKI-2613) [#2617](https://jira.bytedance.com/browse/LKI-2617)
* **feed:** 修改首页FeedNaviBar搜索框的动画效果 ([d38c1f3](https://review.byted.org/#/q/d38c1f3)), closes [#2613](https://jira.bytedance.com/browse/LKI-2613)
* **feed:** 去掉稍后处理成功提示. ([3ec332f](https://review.byted.org/#/q/3ec332f)), closes [#2652](https://jira.bytedance.com/browse/LKI-2652)
* **feed:** 过滤器下拉后，list弹动动效 ([3aa440e](https://review.byted.org/#/q/3aa440e)), closes [#2614](https://jira.bytedance.com/browse/LKI-2614)
* **file:** 修复【附件】点击附件后菊花卡住 ([a59e52d](https://review.byted.org/#/q/a59e52d)), closes [#2683](https://jira.bytedance.com/browse/LKI-2683)
* **LB Bug:** 修复文档数据请求的crash, 修复数据埋点判空可能导致的潜在bug ([bc6eee6](https://review.byted.org/#/q/bc6eee6))
* **message:** chatvc title文字不居中 ([429e3a8](https://review.byted.org/#/q/429e3a8)), closes [#2671](https://jira.bytedance.com/browse/LKI-2671)
* **message:** Thread detail GIF bug fix ([b8c832e](https://review.byted.org/#/q/b8c832e)), closes [#2658](https://jira.bytedance.com/browse/LKI-2658)
* **message:** 修复消息高度不正确的问题. ([b5ecc5d](https://review.byted.org/#/q/b5ecc5d)), closes [#2650](https://jira.bytedance.com/browse/LKI-2650)
* **message:** 内嵌chatvc提供通过chat获取vc的request ([4272ef9](https://review.byted.org/#/q/4272ef9)), closes [#2608](https://jira.bytedance.com/browse/LKI-2608)
* **message:** 卡片消息unknown处理 ([602948a](https://review.byted.org/#/q/602948a)), closes [#2699](https://jira.bytedance.com/browse/LKI-2699)
* **message:** 卡片消息调整 ([25b01da](https://review.byted.org/#/q/25b01da)), closes [#2633](https://jira.bytedance.com/browse/LKI-2633)
* **message:** 消息push时，account为空时crash ([62d6555](https://review.byted.org/#/q/62d6555)), closes [#2688](https://jira.bytedance.com/browse/LKI-2688)
* **message:** 视频消息fileDeleted详情页逻辑修改 ([513f528](https://review.byted.org/#/q/513f528)), closes [#2685](https://jira.bytedance.com/browse/LKI-2685)
* **mine:** 升级检查 crash 修复 ([9383b83](https://review.byted.org/#/q/9383b83)), closes [#2643](https://jira.bytedance.com/browse/LKI-2643)
* **resource:** Logout  点击两次RustKFImageDownloader crash ([c2bfca8](https://review.byted.org/#/q/c2bfca8)), closes [#2659](https://jira.bytedance.com/browse/LKI-2659)
* **search:** 修复搜索机器人，点击，再返回，搜索界面没有响应的问题 ([b06903e](https://review.byted.org/#/q/b06903e)), closes [#2610](https://jira.bytedance.com/browse/LKI-2610)
* **search:** 修正会话内搜索跳转chatvc identifier清空方式 ([b60770f](https://review.byted.org/#/q/b60770f)), closes [#2665](https://jira.bytedance.com/browse/LKI-2665)
* **search:** 搜索结果中bot直接进入会话页面，不应该进入名片 ([84da993](https://review.byted.org/#/q/84da993)), closes [#2679](https://jira.bytedance.com/browse/LKI-2679)
* 去除强解包逻辑 ([97346e1](https://review.byted.org/#/q/97346e1))
* **tabBar:** 修复TabBar重复点击判定bug ([e95f51d](https://review.byted.org/#/q/e95f51d))
* Docs中navigation icon对齐Lark ([82e70df](https://review.byted.org/#/q/82e70df))
* larkcore去除byteview依赖 ([ed046ed](https://review.byted.org/#/q/ed046ed))
* 修改feature总是引用常量问题。 ([b675d87](https://review.byted.org/#/q/b675d87))
* 同步FeedNavBar箭头方向 ([aaf8fc2](https://review.byted.org/#/q/aaf8fc2))
* 键盘增加扩展。 ([0aa767f](https://review.byted.org/#/q/0aa767f))


### Features

* **byteview:** 视频会议0.2.0 功能 & 更新 login 模块 ([2774532](https://review.byted.org/#/q/2774532)), closes [#2662](https://jira.bytedance.com/browse/LKI-2662)
* **chat:** 密聊阅后即焚时间修改. ([d2d94b8](https://review.byted.org/#/q/d2d94b8)), closes [#2641](https://jira.bytedance.com/browse/LKI-2641)
* **chat:** 添加发送消息失败检测， 弹出对应提示 ([a1a61dc](https://review.byted.org/#/q/a1a61dc)), closes [#2536](https://jira.bytedance.com/browse/LKI-2536)
* **component:** 系统分享，增加一个 send to me 的按钮。发送给自己不需要确认 ([6296152](https://review.byted.org/#/q/6296152)), closes [#2584](https://jira.bytedance.com/browse/LKI-2584)
* **component:** 系统分享，增加一个 send to me 的按钮。点击后，不用选人，直接发送给自己。 ([6c327bc](https://review.byted.org/#/q/6c327bc)), closes [#2584](https://jira.bytedance.com/browse/LKI-2584)
* **contact:** 修复离职标签 ([29e0193](https://review.byted.org/#/q/29e0193)), closes [#2664](https://jira.bytedance.com/browse/LKI-2664)
* **contact:** 修复离职标签 ([9ee9b9d](https://review.byted.org/#/q/9ee9b9d)), closes [#2664](https://jira.bytedance.com/browse/LKI-2664)
* **contact:** 修复离职标签 ([c533846](https://review.byted.org/#/q/c533846)), closes [#2664](https://jira.bytedance.com/browse/LKI-2664)
* **contact:** 修改Search相应PB ([83bd25f](https://review.byted.org/#/q/83bd25f)), closes [#2623](https://jira.bytedance.com/browse/LKI-2623)
* **contact:** 修改部分错误 ([b7d9739](https://review.byted.org/#/q/b7d9739)), closes [#2582](https://jira.bytedance.com/browse/LKI-2582)
* **contact:** 增加Mine入口并修复添加有Bug ([73af78f](https://review.byted.org/#/q/73af78f)), closes [#2636](https://jira.bytedance.com/browse/LKI-2636)
* **contact:** 屏蔽外租户电话入口，修复申请后applybutton状态未改变 ([a4b0f8e](https://review.byted.org/#/q/a4b0f8e)), closes [#2645](https://jira.bytedance.com/browse/LKI-2645)
* **contact:** 屏蔽机器人进入personCard入口以及call入口 ([0cd78c3](https://review.byted.org/#/q/0cd78c3)), closes [#2647](https://jira.bytedance.com/browse/LKI-2647)
* **contact:** 添加contactBadge,修复bug ([097833b](https://review.byted.org/#/q/097833b)), closes [#2639](https://jira.bytedance.com/browse/LKI-2639)
* **contact:** 添加CrossTenantFG ([b3af7a6](https://review.byted.org/#/q/b3af7a6)), closes [#2663](https://jira.bytedance.com/browse/LKI-2663)
* **contact:** 添加search相关逻辑 ([5066240](https://review.byted.org/#/q/5066240)), closes [#2578](https://jira.bytedance.com/browse/LKI-2578)
* **contact:** 添加tenant逻辑 ([1c643fb](https://review.byted.org/#/q/1c643fb)), closes [#2600](https://jira.bytedance.com/browse/LKI-2600)
* **contact:** 添加好友失败错误码 ([d6080ad](https://review.byted.org/#/q/d6080ad)), closes [#2654](https://jira.bytedance.com/browse/LKI-2654)
* **contact:** 添加申请跳转逻辑，抽离ContactRouter ([4cc244e](https://review.byted.org/#/q/4cc244e)), closes [#2627](https://jira.bytedance.com/browse/LKI-2627)
* **contact:** 添加空白页,修改Url传入 ([4a54245](https://review.byted.org/#/q/4a54245)), closes [#2661](https://jira.bytedance.com/browse/LKI-2661)
* **contact:** 离职员工处理 ([fb10389](https://review.byted.org/#/q/fb10389)), closes [#2634](https://jira.bytedance.com/browse/LKI-2634)
* **contact:** 离职相关处理逻辑调整 ([f2b70d9](https://review.byted.org/#/q/f2b70d9)), closes [#2656](https://jira.bytedance.com/browse/LKI-2656)
* **dynamic:** 卡片消息调整 ([3366f31](https://review.byted.org/#/q/3366f31)), closes [#2633](https://jira.bytedance.com/browse/LKI-2633)
* **feed:** feed 中增加稍后处理入口. ([9f8c498](https://review.byted.org/#/q/9f8c498)), closes [#2591](https://jira.bytedance.com/browse/LKI-2591)
* **feed:** feedNavibar动画调整，修复之前偶尔出现的naviBar在tableview向下滑动过程中一闪一闪的问题 ([f09dee3](https://review.byted.org/#/q/f09dee3)), closes [#2524](https://jira.bytedance.com/browse/LKI-2524)
* **feed:** 优化稍后处理逻辑. ([00f11e6](https://review.byted.org/#/q/00f11e6)), closes [#2591](https://jira.bytedance.com/browse/LKI-2591)
* **feed:** 修改Mine入口图标 ([a0392a1](https://review.byted.org/#/q/a0392a1)), closes [#2612](https://jira.bytedance.com/browse/LKI-2612)
* **feed:** 新版“我的”之搜索框调整 ([565f311](https://review.byted.org/#/q/565f311)), closes [#2524](https://jira.bytedance.com/browse/LKI-2524)
* **feed:** 更新LarkUIKit; feed中的[Unread]   [Draft]  首字母都要大写. ([b47c163](https://review.byted.org/#/q/b47c163)), closes [#2591](https://jira.bytedance.com/browse/LKI-2591)
* **feed:** 稍后处理埋点 ([32e3951](https://review.byted.org/#/q/32e3951)), closes [#2637](https://jira.bytedance.com/browse/LKI-2637)
* **login:** 更新 eelogin h5页面。 & 更新DocsSDK解决解压资源问题 ([678db31](https://review.byted.org/#/q/678db31)), closes [#2662](https://jira.bytedance.com/browse/LKI-2662)
* **message:** 【视频消息】密聊的视频消息用附件发送 ([b1960bc](https://review.byted.org/#/q/b1960bc)), closes [#2719](https://jira.bytedance.com/browse/LKI-2719)
* **message:** MediaContent detail ([6389c22](https://review.byted.org/#/q/6389c22)), closes [#2403](https://jira.bytedance.com/browse/LKI-2403)
* **message:** video消息详情页fix ([a98aa99](https://review.byted.org/#/q/a98aa99)), closes [#2403](https://jira.bytedance.com/browse/LKI-2403)
* **message:** 视频消息上线 ([c22811f](https://review.byted.org/#/q/c22811f)), closes [#2398](https://jira.bytedance.com/browse/LKI-2398)
* **message:** 视频消息上线： ([a2b62c1](https://review.byted.org/#/q/a2b62c1)), closes [#2398](https://jira.bytedance.com/browse/LKI-2398)
* **message:** 视频消息上线:  长按菜单添加静音播放按钮，为下一步对接静音播放做准备；修复保存视频不在主线程调Driver的问题； 删除失效的ActionMessage ([f3c178e](https://review.byted.org/#/q/f3c178e)), closes [#2398](https://jira.bytedance.com/browse/LKI-2398)
* **message:** 视频消息上线: 修改读取相册逻辑，去除转码； ([18ad8f6](https://review.byted.org/#/q/18ad8f6)), closes [#2398](https://jira.bytedance.com/browse/LKI-2398)
* **message:** 视频消息上线：修改详情页的点击按钮的顺序 ([9d3e1af](https://review.byted.org/#/q/9d3e1af)), closes [#2398](https://jira.bytedance.com/browse/LKI-2398)
* **message:** 视频消息上线：对接下载进度；添加4G下载提示；静音播放； ([124926f](https://review.byted.org/#/q/124926f)), closes [#2398](https://jira.bytedance.com/browse/LKI-2398)
* **message:** 视频消息上线：添加 “保存到云盘” isByteDancer的判断 ([4877f6b](https://review.byted.org/#/q/4877f6b)), closes [#2398](https://jira.bytedance.com/browse/LKI-2398)
* **message:** 视频消息上线：添加视频被撤回的提示； ([aebc9dc](https://review.byted.org/#/q/aebc9dc)), closes [#2398](https://jira.bytedance.com/browse/LKI-2398)
* **message:** 视频消息上线：视频发送成功删除临时文件 ([e10522f](https://review.byted.org/#/q/e10522f)), closes [#2398](https://jira.bytedance.com/browse/LKI-2398)
* **message:** 视频消息上线：隐藏下载进度 ([d40a511](https://review.byted.org/#/q/d40a511)), closes [#2398](https://jira.bytedance.com/browse/LKI-2398)
* **message:** 视频消息上线：隐藏下载进度,修改代码，避免引起歧义 ([8d0b0ea](https://review.byted.org/#/q/8d0b0ea)), closes [#2398](https://jira.bytedance.com/browse/LKI-2398)
* **message:** 视频消息长按保存、视频播放 ([f75ee88](https://review.byted.org/#/q/f75ee88)), closes [#2409](https://jira.bytedance.com/browse/LKI-2409)
* **mine:** 文档静态链接 url替换 ([3e64344](https://review.byted.org/#/q/3e64344)), closes [#2392](https://jira.bytedance.com/browse/LKI-2392)
* **search:** 1.实现界面间跳转 2.单聊提供会话历史入口 ([34da880](https://review.byted.org/#/q/34da880)), closes [#2585](https://jira.bytedance.com/browse/LKI-2585)
* **search:** 会话内搜索打点 ([d9ad7d0](https://review.byted.org/#/q/d9ad7d0)), closes [#2642](https://jira.bytedance.com/browse/LKI-2642)
* **search:** 会话内搜索支持缓存 ([8ea403f](https://review.byted.org/#/q/8ea403f)), closes [#2632](https://jira.bytedance.com/browse/LKI-2632)
* **search:** 搜索文件结果对接预览页跳转/文件预览页支持跳转到chat ([17a6eba](https://review.byted.org/#/q/17a6eba)), closes [#2586](https://jira.bytedance.com/browse/LKI-2586)
* **search:** 细节调整补全，基本完成会话内搜索需求 ([fafa0af](https://review.byted.org/#/q/fafa0af)), closes [#2519](https://jira.bytedance.com/browse/LKI-2519)
* change DocsSDK branch to lark, multi bugs fixed ([5ae7ee4](https://review.byted.org/#/q/5ae7ee4))
* 升级小程序引擎版本： ([bfeeaa5](https://review.byted.org/#/q/bfeeaa5))
* 日历的会议设置 增加会话记录入口 ([d411933](https://review.byted.org/#/q/d411933))
* **voip:** voip增加反馈机制 ([c5239ac](https://review.byted.org/#/q/c5239ac)), closes [#2560](https://jira.bytedance.com/browse/LKI-2560)



<a name="1.11.0"></a>
# 1.11.0 (2018-08-24)


### Bug Fixes

* **chat:** people机器人里面消息预览和详情页不对应. ([a733884](https://review.byted.org/#/q/a733884)), closes [#2579](https://jira.bytedance.com/browse/LKI-2579)
* **chat:** 修复feedback 键盘return文案 ([d5e5c41](https://review.byted.org/#/q/d5e5c41)), closes [#2478](https://jira.bytedance.com/browse/LKI-2478)
* **chat:** 修复image判断token ([da6411f](https://review.byted.org/#/q/da6411f)), closes [#2564](https://jira.bytedance.com/browse/LKI-2564)
* **chat:** 修复post中translateview布局问题以及反馈键盘return换行 ([58670e6](https://review.byted.org/#/q/58670e6)), closes [#2478](https://jira.bytedance.com/browse/LKI-2478)
* **chat:** 修复translateView布局bug以及menu缺少translate ([d22a102](https://review.byted.org/#/q/d22a102)), closes [#2534](https://jira.bytedance.com/browse/LKI-2534)
* **chat:** 修复贴子页面挂起at页面被dismiss BUG ([8da3b28](https://review.byted.org/#/q/8da3b28)), closes [#2588](https://jira.bytedance.com/browse/LKI-2588)
* **chat:** 修改图片编辑相关bug ([9a9dc07](https://review.byted.org/#/q/9a9dc07)), closes [#2557](https://jira.bytedance.com/browse/LKI-2557) [#2561](https://jira.bytedance.com/browse/LKI-2561)
* **component:** 修复协议签署弹窗样式,改成左对齐 ([3b5d1a6](https://review.byted.org/#/q/3b5d1a6)), closes [#2540](https://jira.bytedance.com/browse/LKI-2540)
* **component:** 修复头条圈点击刷新崩溃的问题 ([e05744f](https://review.byted.org/#/q/e05744f))
* **component:** 修复收藏语音进度错误 ([51a0673](https://review.byted.org/#/q/51a0673)), closes [#2517](https://jira.bytedance.com/browse/LKI-2517)
* **component:** 更新LarkUIkit，修复图片裁剪不生效的问题 ([a35b49f](https://review.byted.org/#/q/a35b49f)), closes [#2599](https://jira.bytedance.com/browse/LKI-2599)
* **component:** 更新LarkUIkit，修复添加文字功能不生效的问题 ([1e5748a](https://review.byted.org/#/q/1e5748a)), closes [#2599](https://jira.bytedance.com/browse/LKI-2599)
* **contact:** 修复personCard进入Leader的personCard会crash ([62d3e7a](https://review.byted.org/#/q/62d3e7a)), closes [#2598](https://jira.bytedance.com/browse/LKI-2598)
* **contact:** 去掉 voip 拨打电话的二次确认弹窗. ([c88101e](https://review.byted.org/#/q/c88101e)), closes [#2539](https://jira.bytedance.com/browse/LKI-2539)
* **contact:** 部门群细节补漏 ([8c69d5d](https://review.byted.org/#/q/8c69d5d)), closes [#2528](https://jira.bytedance.com/browse/LKI-2528)
* **dynamic:** DynamicView crash ([3924cd9](https://review.byted.org/#/q/3924cd9)), closes [#2567](https://jira.bytedance.com/browse/LKI-2567)
* **dynamic:** dynamic支持default lineheight: 4 ([32ac064](https://review.byted.org/#/q/32ac064)), closes [#2572](https://jira.bytedance.com/browse/LKI-2572)
* **favorite:** 修复收藏详情页面点击图片无效果BUG ([459f2a1](https://review.byted.org/#/q/459f2a1)), closes [#2587](https://jira.bytedance.com/browse/LKI-2587)
* **feed:** 去掉 feed 的throttle，提前at的拉取时机 ([7849d00](https://review.byted.org/#/q/7849d00)), closes [#2511](https://jira.bytedance.com/browse/LKI-2511) [#2516](https://jira.bytedance.com/browse/LKI-2516)
* **file:** 修复视频文件过多时候，打开文件列表页过慢的问题 ([f6d5a70](https://review.byted.org/#/q/f6d5a70)), closes [#2465](https://jira.bytedance.com/browse/LKI-2465)
* **file:** 修改文件相关性能埋点没有调用的问题 ([ffa2c50](https://review.byted.org/#/q/ffa2c50)), closes [#1236](https://jira.bytedance.com/browse/LKI-1236)
* **forward:** 修正转发确认弹窗头像ui显示问题 ([acbfa1f](https://review.byted.org/#/q/acbfa1f)), closes [#2547](https://jira.bytedance.com/browse/LKI-2547)
* 适配 LarkNavigationController ([2842abe](https://review.byted.org/#/q/2842abe))
* **LB:** update DocsSDK version to 1.8.3, bug fix ([a6be9f4](https://review.byted.org/#/q/a6be9f4))
* **login:** Cookie同步导致用户不登陆session会被清空 ([76b8b16](https://review.byted.org/#/q/76b8b16)), closes [#2565](https://jira.bytedance.com/browse/LKI-2565)
* **message:** avatarkey为空，头像错乱问题 ([b7c5303](https://review.byted.org/#/q/b7c5303)), closes [#2565](https://jira.bytedance.com/browse/LKI-2565)
* **message:** LarkCore.richtextWalker对于没有的元素增加鲁棒性，去除error ([7f51469](https://review.byted.org/#/q/7f51469)), closes [#2574](https://jira.bytedance.com/browse/LKI-2574)
* **message:** 不可对话chat,详情页屏蔽键盘 ([1cd6e48](https://review.byted.org/#/q/1cd6e48)), closes [#2456](https://jira.bytedance.com/browse/LKI-2456)
* **message:** 修复合并转发消息内容中表情不显示的问题. ([591b9df](https://review.byted.org/#/q/591b9df)), closes [#2506](https://jira.bytedance.com/browse/LKI-2506)
* **message:** 在显示非系统键盘时（表情 语音 图片键盘）唤起menu 会话页偏移错误 ([7245a9c](https://review.byted.org/#/q/7245a9c)), closes [#2544](https://jira.bytedance.com/browse/LKI-2544)
* **message:** 被回复的图片消息撤回后, 在回复消息中不显示图片占位符. ([9f0a54d](https://review.byted.org/#/q/9f0a54d)), closes [#2527](https://jira.bytedance.com/browse/LKI-2527)
* **setting:** 替换 feed 筛选器中密聊的 icon; 修改语言增加错误提示. ([52cfb4a](https://review.byted.org/#/q/52cfb4a)), closes [#2515](https://jira.bytedance.com/browse/LKI-2515)
* **web:** Cookie is defference between web and sdk. ([bfb2aec](https://review.byted.org/#/q/bfb2aec)), closes [#2533](https://jira.bytedance.com/browse/LKI-2533)
* docsSDK 分支共用 ([46906e9](https://review.byted.org/#/q/46906e9))
* 修复上传rutland时报错的问题 ([4bfafd9](https://review.byted.org/#/q/4bfafd9))
* 修复导航栏滑动动画bug ([c565416](https://review.byted.org/#/q/c565416))
* 屏蔽 Docs 未兼容 Logger 逻辑 ([65c2db7](https://review.byted.org/#/q/65c2db7))
* 指定 LarkUIKit 的 commit 号修复编译问题 ([9864bbe](https://review.byted.org/#/q/9864bbe))
* 无网络登陆时，之前的数据丢失 ([7a49a79](https://review.byted.org/#/q/7a49a79))


### Features

* **byteview:** 升级ByteView版本 ([7d66a88](https://review.byted.org/#/q/7d66a88)), closes [#0](https://jira.bytedance.com/browse/LKI-0)
* **chat:**  发图前支持编辑 ([5430e60](https://review.byted.org/#/q/5430e60)), closes [#2477](https://jira.bytedance.com/browse/LKI-2477)
* **chat:**  图片编辑功能UI改版 ([173b9e6](https://review.byted.org/#/q/173b9e6)), closes [#2477](https://jira.bytedance.com/browse/LKI-2477)
* **chat:** 修改发图的时候，点击预览，直接进入单张图片预览界面的问题 ([e27bc49](https://review.byted.org/#/q/e27bc49)), closes [#2477](https://jira.bytedance.com/browse/LKI-2477)
* **chat:** 修改选中编辑图片在邮件内不生效的问题，以及更新LarkUIKit ([ba74411](https://review.byted.org/#/q/ba74411)), closes [#2477](https://jira.bytedance.com/browse/LKI-2477)
* **chat:** 增加搜索群历史消息入口. ([f2ca8fb](https://review.byted.org/#/q/f2ca8fb)), closes [#2513](https://jira.bytedance.com/browse/LKI-2513)
* **component:** add byte rtc engine ([f29e0b2](https://review.byted.org/#/q/f29e0b2)), closes [#2214](https://jira.bytedance.com/browse/LKI-2214)
* **component:** 用户协议 隐私条款 ([7d59c8b](https://review.byted.org/#/q/7d59c8b)), closes [#2257](https://jira.bytedance.com/browse/LKI-2257)
* **component:** 用户协议 隐私条款， 文案替换 ([59c5e33](https://review.byted.org/#/q/59c5e33)), closes [#2257](https://jira.bytedance.com/browse/LKI-2257)
* **component:** 用户协议 隐私条款， 添加 url 打开和富文本解析 ([f1d4b22](https://review.byted.org/#/q/f1d4b22)), closes [#2257](https://jira.bytedance.com/browse/LKI-2257)
* **component:** 用户协议 隐私条款， 添加 url 持久化和打开的方式 ([db4bda4](https://review.byted.org/#/q/db4bda4)), closes [#2257](https://jira.bytedance.com/browse/LKI-2257)
* **component:** 用户协议 隐私条款，修改无论请求结果成功还是失败都不阻碍下一步行为 ([b224f28](https://review.byted.org/#/q/b224f28)), closes [#2257](https://jira.bytedance.com/browse/LKI-2257)
* **contact:** person实现申请，外部联系人 ([1c379fc](https://review.byted.org/#/q/1c379fc)), closes [#2498](https://jira.bytedance.com/browse/LKI-2498)
* **contact:** 主体流程连调完成，相关界面ui上加入部门群标签 ([c275d7a](https://review.byted.org/#/q/c275d7a)), closes [#2493](https://jira.bytedance.com/browse/LKI-2493)
* **contact:** 修改分享群逻辑并添加保存二维码到相册方法 ([d695666](https://review.byted.org/#/q/d695666)), closes [#2504](https://jira.bytedance.com/browse/LKI-2504)
* **contact:** 修正featuregating导致首次无法获取部门群创建权限问题 ([d748c29](https://review.byted.org/#/q/d748c29)), closes [#2573](https://jira.bytedance.com/browse/LKI-2573)
* **contact:** 增添ChatApplicationAPI和ExternalContactsAPI ([97735f4](https://review.byted.org/#/q/97735f4)), closes [#2491](https://jira.bytedance.com/browse/LKI-2491)
* **contact:** 完善shareFriend以及addFriend逻辑 ([73ab8fb](https://review.byted.org/#/q/73ab8fb)), closes [#2499](https://jira.bytedance.com/browse/LKI-2499)
* 分享日程到Lark ([8196ef5](https://review.byted.org/#/q/8196ef5))
* **contact:** 完整对接所有业务流程 ([bcc1a5c](https://review.byted.org/#/q/bcc1a5c)), closes [#2492](https://jira.bytedance.com/browse/LKI-2492)
* **contact:** 接入mineSetting的contact相关逻辑以及ContactApplicationViewController，ExternalContactsViewController的逻辑 ([835357e](https://review.byted.org/#/q/835357e)), closes [#2497](https://jira.bytedance.com/browse/LKI-2497)
* **contact:** 添加Contact的Badge逻辑 ([ee00207](https://review.byted.org/#/q/ee00207)), closes [#2500](https://jira.bytedance.com/browse/LKI-2500)
* **contact:** 添加ExternalContacts相关逻辑 ([289ade4](https://review.byted.org/#/q/289ade4)), closes [#2503](https://jira.bytedance.com/browse/LKI-2503)
* **contact:** 添加外部识别标识 ([9aa3e01](https://review.byted.org/#/q/9aa3e01)), closes [#2501](https://jira.bytedance.com/browse/LKI-2501)
* **contact:** 添加外部链接跳转 ([9e3194c](https://review.byted.org/#/q/9e3194c)), closes [#2502](https://jira.bytedance.com/browse/LKI-2502)
* **contact:** 添加申请过期等逻辑 ([fee276e](https://review.byted.org/#/q/fee276e)), closes [#2505](https://jira.bytedance.com/browse/LKI-2505)
* **contact:** 添加联系人及申请删除逻辑 ([3d1a773](https://review.byted.org/#/q/3d1a773)), closes [#2562](https://jira.bytedance.com/browse/LKI-2562)
* **feed:** Feed 接入 Preload ([39fa34c](https://review.byted.org/#/q/39fa34c)), closes [#2518](https://jira.bytedance.com/browse/LKI-2518)
* **feed:** Feed 接入 Preload 增加 doc preload ([df129e4](https://review.byted.org/#/q/df129e4)), closes [#2518](https://jira.bytedance.com/browse/LKI-2518)
* **feed:** feed页显示部门群标签 ([d35e0bc](https://review.byted.org/#/q/d35e0bc)), closes [#2448](https://jira.bytedance.com/browse/LKI-2448)
* **feed:** 侧边栏 Feed 过滤器改版成下拉式过滤器 ([c862b85](https://review.byted.org/#/q/c862b85)), closes [#2522](https://jira.bytedance.com/browse/LKI-2522)
* **feed:** 修改Mine入口 ([6ef2137](https://review.byted.org/#/q/6ef2137)), closes [#2523](https://jira.bytedance.com/browse/LKI-2523)
* **feed:** 关闭提醒的会话在preview中增加[xx条未读]的展示 ([9d5f1db](https://review.byted.org/#/q/9d5f1db)), closes [#2591](https://jira.bytedance.com/browse/LKI-2591)
* **feed:** 新版feed搜索框调整 ([29c57b2](https://review.byted.org/#/q/29c57b2)), closes [#2524](https://jira.bytedance.com/browse/LKI-2524)
* **feed:** 添加外部过滤器 ([9f4dd93](https://review.byted.org/#/q/9f4dd93)), closes [#2576](https://jira.bytedance.com/browse/LKI-2576)
* **feed:** 稍后处理-UI 调整和增加接口 ([8d4514c](https://review.byted.org/#/q/8d4514c)), closes [#2591](https://jira.bytedance.com/browse/LKI-2591)
* **message:** post 消息增加 copy 操作. ([a426abb](https://review.byted.org/#/q/a426abb)), closes [#2537](https://jira.bytedance.com/browse/LKI-2537)
* **message:** 投票打点支持 ([d0e366d](https://review.byted.org/#/q/d0e366d)), closes [#2532](https://jira.bytedance.com/browse/LKI-2532)
* **message:** 视频消息加急 ([41f8480](https://review.byted.org/#/q/41f8480)), closes [#2408](https://jira.bytedance.com/browse/LKI-2408)
* **message:** 视频消息发送，添加卡片控制; 将部分 [视频消息] 改成 [视频]; 将进度的值 与 status 分开设置 ([f537a00](https://review.byted.org/#/q/f537a00)), closes [#2402](https://jira.bytedance.com/browse/LKI-2402)
* **message:** 视频消息发送+展示 ([d4596a0](https://review.byted.org/#/q/d4596a0)), closes [#2402](https://jira.bytedance.com/browse/LKI-2402)
* **message:** 视频消息发送+展示，添加图片缓存，处理点击事件，添加Action接口 ([64fac3e](https://review.byted.org/#/q/64fac3e)), closes [#2402](https://jira.bytedance.com/browse/LKI-2402)
* hide the tabBar ([76223c5](https://review.byted.org/#/q/76223c5))
* **message:** 视频消息合并转发 ([4643856](https://review.byted.org/#/q/4643856)), closes [#2406](https://jira.bytedance.com/browse/LKI-2406)
* **message:** 视频消息对接图片预览控件 ([5b058e7](https://review.byted.org/#/q/5b058e7)), closes [#2401](https://jira.bytedance.com/browse/LKI-2401)
* **message:** 视频消息支持收藏， 重命名 PreviewImageAction 为 PreviewAssetAction ([a3f7c0c](https://review.byted.org/#/q/a3f7c0c)), closes [#2404](https://jira.bytedance.com/browse/LKI-2404)
* **message:** 视频消息添加Feature gating ([2441030](https://review.byted.org/#/q/2441030)), closes [#2563](https://jira.bytedance.com/browse/LKI-2563)
* **message:** 视频消息转发 ([87689e2](https://review.byted.org/#/q/87689e2)), closes [#2405](https://jira.bytedance.com/browse/LKI-2405)
* **message:** 语音播放时，显示时长倒计时. ([5e046d1](https://review.byted.org/#/q/5e046d1)), closes [#2452](https://jira.bytedance.com/browse/LKI-2452)
* **message:** 配合rust性能统计，GetCardMessagesRequest加入isFirstScreen标示 ([566b5ca](https://review.byted.org/#/q/566b5ca)), closes [#2490](https://jira.bytedance.com/browse/LKI-2490)
* **search:** 会话内搜索容器及模版类实现 ([abea206](https://review.byted.org/#/q/abea206)), closes [#2520](https://jira.bytedance.com/browse/LKI-2520)
* **search:** 会话内搜索接口对接 ([2bceace](https://review.byted.org/#/q/2bceace)), closes [#2525](https://jira.bytedance.com/browse/LKI-2525)
* **search:** 基本完成msg/doc/file搜索界面与展示流程 ([4026938](https://review.byted.org/#/q/4026938)), closes [#2568](https://jira.bytedance.com/browse/LKI-2568)
* delete old webview tab, switch to new native tab ([18e10ce](https://review.byted.org/#/q/18e10ce))
* temporarily change tab entrance ([2f50a16](https://review.byted.org/#/q/2f50a16))
* 接入 Lark 日志系统和上报, 历史记录, 离线文档, bug fix ([2e6e74b](https://review.byted.org/#/q/2e6e74b))



<a name="1.10.1"></a>
## 1.10.1 (2018-08-14)


### Bug Fixes

* **chat:** 单聊设置点击机器人头像闪退 ([78cff6b](https://review.byted.org/#/q/78cff6b)), closes [#2486](https://jira.bytedance.com/browse/LKI-2486)
* **component:** 调整日志层级，升级 logger 库 ([cc5fb24](https://review.byted.org/#/q/cc5fb24)), closes [#2380](https://jira.bytedance.com/browse/LKI-2380)
* **mine:** 升级UI文本可编辑 ([0118b18](https://review.byted.org/#/q/0118b18)), closes [#2482](https://jira.bytedance.com/browse/LKI-2482)


### Features

* **contact:** 1.对接已选择界面逻辑 2.修正搜索页面与toolbar联动不对问题 3.修复toolbarui刷新不对问题 ([39c540f](https://review.byted.org/#/q/39c540f)), closes [#2448](https://jira.bytedance.com/browse/LKI-2448)
* **contact:** 将UserProfile替换ChatterProfile ([135cb5b](https://review.byted.org/#/q/135cb5b)), closes [#2483](https://jira.bytedance.com/browse/LKI-2483)
* **contact:** 建部门群选择子部门vc ([c78a197](https://review.byted.org/#/q/c78a197)), closes [#2474](https://jira.bytedance.com/browse/LKI-2474)
* **contact:** 添加application相关pb及Model ([6e29d1e](https://review.byted.org/#/q/6e29d1e)), closes [#2481](https://jira.bytedance.com/browse/LKI-2481)



<a name="1.10.0"></a>
# 1.10.0 (2018-08-13)


### Bug Fixes

* **message:** 修正cell背景颜色不对的问题 ([1f3d8e2](https://review.byted.org/#/q/1f3d8e2)), closes [#2433](https://jira.bytedance.com/browse/LKI-2433)
* fix ui bug in at view controller ([fb1767e](https://review.byted.org/#/q/fb1767e))
* **component:** 修复个人名片页面布局错误 ([6535edd](https://review.byted.org/#/q/6535edd)), closes [#2439](https://jira.bytedance.com/browse/LKI-2439)
* **component:** 修正loadingswitch导致的崩溃问题 ([09c8951](https://review.byted.org/#/q/09c8951)), closes [#2430](https://jira.bytedance.com/browse/LKI-2430)
* **component:** 配合loadingswitch导致的崩溃问题更新larkuikit ([cecca4a](https://review.byted.org/#/q/cecca4a)), closes [#2430](https://jira.bytedance.com/browse/LKI-2430)
* **docs:** minor bug fix in docs ([f180471](https://review.byted.org/#/q/f180471))
* **Docs:** minor bug fix in loading logic ([4025fe0](https://review.byted.org/#/q/4025fe0))
* **Docs:** ui adjust ([2c0af76](https://review.byted.org/#/q/2c0af76))
* **Docs:** ui bug fix ([4153e48](https://review.byted.org/#/q/4153e48))
* **favorite:** 收藏异步初始化ui ([b25023c](https://review.byted.org/#/q/b25023c)), closes [#2450](https://jira.bytedance.com/browse/LKI-2450)
* **feed:** 修复优化双击tab缓冲tableview刷新时没放开buffer队列导致done Feed不刷新的问题 ([dd38e19](https://review.byted.org/#/q/dd38e19)), closes [#2476](https://jira.bytedance.com/browse/LKI-2476)
* **feed:** 完善 Feed 新的排序机制 ([e3b208d](https://review.byted.org/#/q/e3b208d)), closes [#2113](https://jira.bytedance.com/browse/LKI-2113)
* **feed:** 搜索历史的 p2p chat 的feedId 取错 ([07d5eb9](https://review.byted.org/#/q/07d5eb9)), closes [#2113](https://jira.bytedance.com/browse/LKI-2113)
* **message:** (1)解决会话内上气泡可能消失不掉的问题 (2)优化上未读气泡getunreadmsg接口调用策略 ([8c69631](https://review.byted.org/#/q/8c69631)), closes [#2377](https://jira.bytedance.com/browse/LKI-2377) [#2378](https://jira.bytedance.com/browse/LKI-2378)
* **message:** DynamicViewProtocol lead UIView init not fount crash ([2191465](https://review.byted.org/#/q/2191465)), closes [#2430](https://jira.bytedance.com/browse/LKI-2430)
* **message:** LoadingSwtich() crash fix ([6194bd0](https://review.byted.org/#/q/6194bd0)), closes [#2430](https://jira.bytedance.com/browse/LKI-2430)
* 视频会议流量提示修复 ([223ffc6](https://review.byted.org/#/q/223ffc6))
* **message:** SetImage forceOrigin ([f0923c1](https://review.byted.org/#/q/f0923c1)), closes [#2432](https://jira.bytedance.com/browse/LKI-2432)
* **message:** 修复SetAvatar延迟释放 && 修复MergeForward循环引用 ([fb500bb](https://review.byted.org/#/q/fb500bb)), closes [#2475](https://jira.bytedance.com/browse/LKI-2475)
* **message:** 密聊消息在线推送不展示 title, sdk 有可能会出问题, 限制一下. ([1f2d567](https://review.byted.org/#/q/1f2d567)), closes [#2393](https://jira.bytedance.com/browse/LKI-2393)
* **message:** 查看大图placeholder消息问题 ([e89fbf9](https://review.byted.org/#/q/e89fbf9)), closes [#2437](https://jira.bytedance.com/browse/LKI-2437)
* **setting:** 修改部分国际化文案. ([a4c56cd](https://review.byted.org/#/q/a4c56cd)), closes [#2391](https://jira.bytedance.com/browse/LKI-2391)
* **setting:** 修改部分在线 push 不显示详情时的文案. ([7b2defc](https://review.byted.org/#/q/7b2defc)), closes [#2391](https://jira.bytedance.com/browse/LKI-2391)
* **voip:** 修复电话头像显示错误问题 ([6eba9d1](https://review.byted.org/#/q/6eba9d1)), closes [#2440](https://jira.bytedance.com/browse/LKI-2440)


### Features

* **byteview:** refactor interface ([01e1900](https://review.byted.org/#/q/01e1900)), closes [#6](https://jira.bytedance.com/browse/LKI-6)
* **byteview:** 更新 ByteView 版本 ([a2f0034](https://review.byted.org/#/q/a2f0034)), closes [#364](https://jira.bytedance.com/browse/LKI-364)
* **chat:** chat/email会话界面加载时长打点 ([2e141b4](https://review.byted.org/#/q/2e141b4)), closes [#2447](https://jira.bytedance.com/browse/LKI-2447)
* **chat:** LarkSchema支持新的url规则 ([c257671](https://review.byted.org/#/q/c257671)), closes [#2388](https://jira.bytedance.com/browse/LKI-2388)
* **chat:** translate打点 ([7f5b055](https://review.byted.org/#/q/7f5b055)), closes [#2240](https://jira.bytedance.com/browse/LKI-2240)
* **chat:** 会话加载性能埋点 ([d47d90c](https://review.byted.org/#/q/d47d90c)), closes [#2447](https://jira.bytedance.com/browse/LKI-2447)
* **chat:** 密聊下只能发送本地文件, 屏蔽云盘文件入口. ([bfd1d46](https://review.byted.org/#/q/bfd1d46)), closes [#2416](https://jira.bytedance.com/browse/LKI-2416)
* **chat:** 抽离贴子编辑页面 ([b4fc268](https://review.byted.org/#/q/b4fc268)), closes [#2385](https://jira.bytedance.com/browse/LKI-2385)
* **component:** 下沉编辑转化相关组件 ([e08177a](https://review.byted.org/#/q/e08177a)), closes [#2386](https://jira.bytedance.com/browse/LKI-2386)
* **component:** 拆分 voip demo ([8f27a0b](https://review.byted.org/#/q/8f27a0b)), closes [#2379](https://jira.bytedance.com/browse/LKI-2379)
* **component:** 提供一个强制登出的接口，调用之后清除本地数据 ([db2ce46](https://review.byted.org/#/q/db2ce46)), closes [#2315](https://jira.bytedance.com/browse/LKI-2315)
* **contact:** 1.获取下属部门 2.根据是否有子部门控制建群入口 ([72fc701](https://review.byted.org/#/q/72fc701)), closes [#2471](https://jira.bytedance.com/browse/LKI-2471)
* **contact:** MineSetting添加contact按钮以及Contact添加Contact Applicationy页面 ([0d40824](https://review.byted.org/#/q/0d40824)), closes [#2415](https://jira.bytedance.com/browse/LKI-2415)
* **contact:** 创建群聊页面UI初步调整完成,基本对接完内部群UI主体流程 ([b506614](https://review.byted.org/#/q/b506614)), closes [#2448](https://jira.bytedance.com/browse/LKI-2448)
* **contact:** 完成内部群逻辑流程 ([b7af966](https://review.byted.org/#/q/b7af966)), closes [#2467](https://jira.bytedance.com/browse/LKI-2467)
* **contact:** 添加ExternalContacts ([67a9329](https://review.byted.org/#/q/67a9329)), closes [#2423](https://jira.bytedance.com/browse/LKI-2423)
* **contact:** 添加personcard相关cell及逻辑 ([fab6b03](https://review.byted.org/#/q/fab6b03)), closes [#2469](https://jira.bytedance.com/browse/LKI-2469)
* **contact:** 添加分享好友UI ([4b2d564](https://review.byted.org/#/q/4b2d564)), closes [#2431](https://jira.bytedance.com/browse/LKI-2431)
* **contact:** 添加申请好友UI ([235adda](https://review.byted.org/#/q/235adda)), closes [#2443](https://jira.bytedance.com/browse/LKI-2443)
* **login:** set osession when login ([81ed71a](https://review.byted.org/#/q/81ed71a)), closes [#2369](https://jira.bytedance.com/browse/LKI-2369)
* **message:** Lark Card use ([92980ca](https://review.byted.org/#/q/92980ca)), closes [#2114](https://jira.bytedance.com/browse/LKI-2114)
* **message:** LarkDynamic Base ([1eca0bd](https://review.byted.org/#/q/1eca0bd)), closes [#2420](https://jira.bytedance.com/browse/LKI-2420)
* **message:** LarkDynamic component ([eb1d2d0](https://review.byted.org/#/q/eb1d2d0)), closes [#2421](https://jira.bytedance.com/browse/LKI-2421)
* **message:** LarkModel update ([46afa73](https://review.byted.org/#/q/46afa73)), closes [#2422](https://jira.bytedance.com/browse/LKI-2422)
* fix loading bug, fix share bugs ([20c0ab7](https://review.byted.org/#/q/20c0ab7))
* **message:** support AnchorProperty.textContent ([3c34444](https://review.byted.org/#/q/3c34444)), closes [#2412](https://jira.bytedance.com/browse/LKI-2412)
* **message:** 发送中消息支持删除 ([fcbeec3](https://review.byted.org/#/q/fcbeec3)), closes [#2491](https://jira.bytedance.com/browse/LKI-2491)
* **message:** 投票二期SelectOption修改 ([131a390](https://review.byted.org/#/q/131a390)), closes [#2323](https://jira.bytedance.com/browse/LKI-2323)
* **message:** 投票二期Title修改 ([82f40ad](https://review.byted.org/#/q/82f40ad)), closes [#2322](https://jira.bytedance.com/browse/LKI-2322)
* **message:** 投票消息屏蔽转发入口 ([54785b8](https://review.byted.org/#/q/54785b8)), closes [#2376](https://jira.bytedance.com/browse/LKI-2376)
* **message:** 视频消息发送 ([ae4705d](https://review.byted.org/#/q/ae4705d)), closes [#2402](https://jira.bytedance.com/browse/LKI-2402)
* **message:** 视频消息发送+展示 ([e131a5e](https://review.byted.org/#/q/e131a5e)), closes [#2402](https://jira.bytedance.com/browse/LKI-2402)



<a name="1.9.1"></a>
## 1.9.1 (2018-08-01)


### Bug Fixes

* **chat:** feed 中的密聊会话按照时间序排序. ([dc29556](https://review.byted.org/#/q/dc29556)), closes [#2318](https://jira.bytedance.com/browse/LKI-2318)
* **chat:** translateMessage缺失导致无法拉取之前的消息 ([f815cd4](https://review.byted.org/#/q/f815cd4)), closes [#2339](https://jira.bytedance.com/browse/LKI-2339)
* **chat:** 优化密聊 UI 效果. ([266b65b](https://review.byted.org/#/q/266b65b)), closes [#1830](https://jira.bytedance.com/browse/LKI-1830)
* **chat:** 修复feedback弹窗动画重复 ([57bb70c](https://review.byted.org/#/q/57bb70c)), closes [#2319](https://jira.bytedance.com/browse/LKI-2319)
* **chat:** 修复上传文件进度条会后退的问题 ([8fe5071](https://review.byted.org/#/q/8fe5071)), closes [#2332](https://jira.bytedance.com/browse/LKI-2332)
* **chat:** 修复会话中发doc交互 ([90471e4](https://review.byted.org/#/q/90471e4)), closes [#2280](https://jira.bytedance.com/browse/LKI-2280)
* **chat:** 修复会话键盘不释放BUG ([cc2ea6c](https://review.byted.org/#/q/cc2ea6c)), closes [#2371](https://jira.bytedance.com/browse/LKI-2371)
* **chat:** 修复视频会议气泡无法显示 ([3c35931](https://review.byted.org/#/q/3c35931)), closes [#2289](https://jira.bytedance.com/browse/LKI-2289)
* **chat:** 修复约束导致长文本右边被截的问题. ([0c0db39](https://review.byted.org/#/q/0c0db39)), closes [#2267](https://jira.bytedance.com/browse/LKI-2267)
* **chat:** 修改setAvatar内存泄露 ([924e9e6](https://review.byted.org/#/q/924e9e6)), closes [#2233](https://jira.bytedance.com/browse/LKI-2233)
* **chat:** 修改translate判断key ([c8a53a8](https://review.byted.org/#/q/c8a53a8)), closes [#2343](https://jira.bytedance.com/browse/LKI-2343)
* **chat:** 密聊先去掉发送 post 入口, 优化阅后即焚刷新机制. ([c0d8c26](https://review.byted.org/#/q/c0d8c26)), closes [#1830](https://jira.bytedance.com/browse/LKI-1830)
* **chat:** 富文本中的图片在主线程初始化 ([982f3d5](https://review.byted.org/#/q/982f3d5)), closes [#2373](https://jira.bytedance.com/browse/LKI-2373)
* **chat:** 解message拉取失败 ([dd0b3fb](https://review.byted.org/#/q/dd0b3fb)), closes [#2343](https://jira.bytedance.com/browse/LKI-2343)
* **component:** actionSheet支持点击态 ([9055fd6](https://review.byted.org/#/q/9055fd6)), closes [#2224](https://jira.bytedance.com/browse/LKI-2224)
* **component:** actionSheet高亮优化及UI调整 ([361f4d2](https://review.byted.org/#/q/361f4d2)), closes [#2224](https://jira.bytedance.com/browse/LKI-2224)
* **component:** customActionSheet点击高亮 ([da62f71](https://review.byted.org/#/q/da62f71)), closes [#2224](https://jira.bytedance.com/browse/LKI-2224)
* **component:** 不可用提示选项中去掉钉钉群选项 ([922f89c](https://review.byted.org/#/q/922f89c)), closes [#2206](https://jira.bytedance.com/browse/LKI-2206)
* **component:** 为doc提供打开url链接的方法 ([8e32acd](https://review.byted.org/#/q/8e32acd)), closes [#2220](https://jira.bytedance.com/browse/LKI-2220)
* **component:** 修复ZoomSDK的category colorWithHexString冲突而且返回颜色出错，导致小程序状态栏显示不正常的问题。 ([9bdd7c1](https://review.byted.org/#/q/9bdd7c1)), closes [#2307](https://jira.bytedance.com/browse/LKI-2307)
* **component:** 修复安全模式登出后，所有的UserDefualt文件也被删除的问题 ([c46b969](https://review.byted.org/#/q/c46b969)), closes [#2308](https://jira.bytedance.com/browse/LKI-2308)
* **component:** 修正旋转不正确问题 ([dfeb1a0](https://review.byted.org/#/q/dfeb1a0)), closes [#2227](https://jira.bytedance.com/browse/LKI-2227)
* **component:** 点击别人头像也会显示编辑头像 ([a1dcb72](https://review.byted.org/#/q/a1dcb72)), closes [#2349](https://jira.bytedance.com/browse/LKI-2349)
* **component:** 补充修复安全模式登出后，UserDefault清空的问题 ([07dc844](https://review.byted.org/#/q/07dc844)), closes [#2308](https://jira.bytedance.com/browse/LKI-2308)
* **component:** 退出登录失败会跳到首页 ([792d030](https://review.byted.org/#/q/792d030)), closes [#2297](https://jira.bytedance.com/browse/LKI-2297)
* **contact:** 修复添加群成员上限弹窗不显示的问题. ([c0b8322](https://review.byted.org/#/q/c0b8322)), closes [#2336](https://jira.bytedance.com/browse/LKI-2336)
* **contact:** 修复点击别人头像也会显示编辑头像. ([2bb94d0](https://review.byted.org/#/q/2bb94d0)), closes [#2349](https://jira.bytedance.com/browse/LKI-2349)
* **contact:** 创建群聊的时候，点击完成，收起键盘 ([7bd2a49](https://review.byted.org/#/q/7bd2a49)), closes [#2288](https://jira.bytedance.com/browse/LKI-2288)
* **docs:** 调整docs链接中的from参数值 ([6fb53b6](https://review.byted.org/#/q/6fb53b6)), closes [#2149](https://jira.bytedance.com/browse/LKI-2149)
* **Docs:** minor ui bug fix in docs navigation bar ([57f10f3](https://review.byted.org/#/q/57f10f3))
* **Docs:** minor ui bug fix in docs navigation bar ([bdc60d7](https://review.byted.org/#/q/bdc60d7))
* **Docs:** 多租户UI bug fix, docs sdk 多项细节bug修复, 更新podfile.lock ([160a6f8](https://review.byted.org/#/q/160a6f8))
* **Docs:** 多租户UI bug fix, docs sdk 多项细节bug修复, 更新podfile.lock ([b223b4a](https://review.byted.org/#/q/b223b4a))
* **email:** [邮件]邮件@他人后发送出去，折叠后的回复消息出现两个@ ([2ef39ba](https://review.byted.org/#/q/2ef39ba)), closes [#2034](https://jira.bytedance.com/browse/LKI-2034)
* **email:** Mail.subject字段填充问题 ([5aa1c3d](https://review.byted.org/#/q/5aa1c3d)), closes [#2251](https://jira.bytedance.com/browse/LKI-2251)
* **email:** Mail.subject字段填充问题 ([a4d6750](https://review.byted.org/#/q/a4d6750)), closes [#2251](https://jira.bytedance.com/browse/LKI-2251)
* **email:** 修复添加邮件参与者页面，有的cell头像名字显示为空的问题 ([44a091a](https://review.byted.org/#/q/44a091a)), closes [#2284](https://jira.bytedance.com/browse/LKI-2284)
* **email:** 修复邮件 emoji 草稿错误问题 ([8100cd0](https://review.byted.org/#/q/8100cd0)), closes [#2305](https://jira.bytedance.com/browse/LKI-2305)
* **email:** 修复邮件显示图片出错问题 ([3e47c1b](https://review.byted.org/#/q/3e47c1b)), closes [#2278](https://jira.bytedance.com/browse/LKI-2278)
* **favorite:** 修复收藏贴子显示图片失败 ([9b31c06](https://review.byted.org/#/q/9b31c06)), closes [#2352](https://jira.bytedance.com/browse/LKI-2352)
* **login:** 非登录状态下进入后台奔溃 ([89e5240](https://review.byted.org/#/q/89e5240)), closes [#2279](https://jira.bytedance.com/browse/LKI-2279)
* **message:** chatvc tableIsAtBottom实现调整，解决回复消息后，消息被键盘遮挡的问题 ([9677ced](https://review.byted.org/#/q/9677ced)), closes [#2248](https://jira.bytedance.com/browse/LKI-2248)
* **message:** doc history 使用 id 作为唯一标识 ([106c451](https://review.byted.org/#/q/106c451)), closes [#2269](https://jira.bytedance.com/browse/LKI-2269)
* **message:** more 键盘添加 top border ([8d0b068](https://review.byted.org/#/q/8d0b068)), closes [#2320](https://jira.bytedance.com/browse/LKI-2320)
* **message:** RichText setImage ([0ca1ec8](https://review.byted.org/#/q/0ca1ec8)), closes [#2232](https://jira.bytedance.com/browse/LKI-2232)
* **message:** SetImageService修改 ([5c97ae5](https://review.byted.org/#/q/5c97ae5)), closes [#2355](https://jira.bytedance.com/browse/LKI-2355)
* **message:** url 渲染使用 preview url 字段. ([4adff01](https://review.byted.org/#/q/4adff01)), closes [#2335](https://jira.bytedance.com/browse/LKI-2335)
* **message:** 修复"翻译功能"引入的@已读未读状态显示不正确的问题. ([d44ad35](https://review.byted.org/#/q/d44ad35)), closes [#2290](https://jira.bytedance.com/browse/LKI-2290)
* fix a crash bug in iOS10 ([ebbecd8](https://review.byted.org/#/q/ebbecd8))
* **message:** 修复@人的小绿点显示不正确的问题, 对 sdk 的 bug 进行容错处理. ([a2c9b14](https://review.byted.org/#/q/a2c9b14)), closes [#2333](https://jira.bytedance.com/browse/LKI-2333)
* **message:** 修复more键盘底色 ([5a719f2](https://review.byted.org/#/q/5a719f2)), closes [#2320](https://jira.bytedance.com/browse/LKI-2320)
* **message:** 修复发送doc cell icon ([edc1a9e](https://review.byted.org/#/q/edc1a9e)), closes [#2324](https://jira.bytedance.com/browse/LKI-2324)
* **message:** 修复头像模糊问题 ([f89ee6f](https://review.byted.org/#/q/f89ee6f)), closes [#2277](https://jira.bytedance.com/browse/LKI-2277)
* **message:** 修复电话加急消息一直 loading 的问题. ([427aec3](https://review.byted.org/#/q/427aec3)), closes [#2047](https://jira.bytedance.com/browse/LKI-2047)
* **message:** 修复贴子转richText错误问题 ([db42a16](https://review.byted.org/#/q/db42a16)), closes [#2321](https://jira.bytedance.com/browse/LKI-2321)
* **message:** 修复部分消息的reaction，当人数较多时不会展示等...人信息，而是直接截断人名的问题. ([a3b2b79](https://review.byted.org/#/q/a3b2b79)), closes [#2351](https://jira.bytedance.com/browse/LKI-2351)
* **message:** 处理rust返回unReadIds为空导致@人已读状态错误的问题. ([bbaffe0](https://review.byted.org/#/q/bbaffe0)), closes [#2235](https://jira.bytedance.com/browse/LKI-2235)
* **message:** 头像模糊问题 ([ba0a7d8](https://review.byted.org/#/q/ba0a7d8)), closes [#2277](https://jira.bytedance.com/browse/LKI-2277)
* **message:** 密聊下不能点击回复数进入详情页. ([697498e](https://review.byted.org/#/q/697498e)), closes [#2282](https://jira.bytedance.com/browse/LKI-2282)
* **message:** 添加 send doc UI 问题 ([280b568](https://review.byted.org/#/q/280b568)), closes [#2310](https://jira.bytedance.com/browse/LKI-2310)
* 气泡消息字符串改为decode，增加会议气泡图标。 ([7897eb2](https://review.byted.org/#/q/7897eb2))
* **message:** 解决pack重构时引入的群分享消息缺失chat时，导致会话无法正常加载 ([01b056d](https://review.byted.org/#/q/01b056d)), closes [#2316](https://jira.bytedance.com/browse/LKI-2316)
* **message:** 解决偶尔回复消息时，键盘遮挡最后一条消息的问题 ([6cbdaf7](https://review.byted.org/#/q/6cbdaf7)), closes [#2015](https://jira.bytedance.com/browse/LKI-2015)
* **message:** 解决头像模糊问题默认参数显示编辑按钮问题 ([14f83e8](https://review.byted.org/#/q/14f83e8)), closes [#2343](https://jira.bytedance.com/browse/LKI-2343)
* **message:** 键盘中表情出现两份 ([26b21d7](https://review.byted.org/#/q/26b21d7)), closes [#2361](https://jira.bytedance.com/browse/LKI-2361)
* **search:** 在点击email的时候，去网络取email(本地很有可能没有) ([6dc617f](https://review.byted.org/#/q/6dc617f)), closes [#2285](https://jira.bytedance.com/browse/LKI-2285)
* **search:** 日历调用搜索，场景切换 ([9f68823](https://review.byted.org/#/q/9f68823)), closes [#2370](https://jira.bytedance.com/browse/LKI-2370)
* **search:** 转发搜索，和邮件中的搜索修改为分页加载 ([25a0d63](https://review.byted.org/#/q/25a0d63)), closes [#2296](https://jira.bytedance.com/browse/LKI-2296)
* 卡片title人名不显示修复并增加断言 ([a51a629](https://review.byted.org/#/q/a51a629))
* **setting:** 使用PM 翻译的文案全面国际化. ([98514d1](https://review.byted.org/#/q/98514d1)), closes [#2234](https://jira.bytedance.com/browse/LKI-2234)
* **setting:** 修改部分国际化文案, 优化文案显示. ([6499a98](https://review.byted.org/#/q/6499a98)), closes [#2287](https://jira.bytedance.com/browse/LKI-2287)
* **share:** iOS 系统截图-分享，报文件格式错误, 优化缩略图获取 ([8dcae2f](https://review.byted.org/#/q/8dcae2f)), closes [#2291](https://jira.bytedance.com/browse/LKI-2291)
* **voip:** 修复 voip 后台音乐 与 遮挡 BUG ([8248d99](https://review.byted.org/#/q/8248d99)), closes [#2222](https://jira.bytedance.com/browse/LKI-2222)
* **web:** 修复头条全上传图片问题 ([35dbe7d](https://review.byted.org/#/q/35dbe7d)), closes [#2302](https://jira.bytedance.com/browse/LKI-2302)


### Features

* **byteview:** 实现视频会议功能，合入byteview代码 ([f0317ee](https://review.byted.org/#/q/f0317ee)), closes [#6](https://jira.bytedance.com/browse/LKI-6)
* **chat:** chat 页面, 密聊不能进入详情页. ([9c272ec](https://review.byted.org/#/q/9c272ec)), closes [#2262](https://jira.bytedance.com/browse/LKI-2262)
* **chat:** feed 加密消息最后一条消息描述由 sdk 处理. ([1db1c8d](https://review.byted.org/#/q/1db1c8d)), closes [#1830](https://jira.bytedance.com/browse/LKI-1830)
* **chat:** feed中密聊 done 操作解散密聊会话, 增加弹窗确认提示. ([9bf3689](https://review.byted.org/#/q/9bf3689)), closes [#2247](https://jira.bytedance.com/browse/LKI-2247)
* **chat:** thread支持群主撤回消息展示 ([08685fb](https://review.byted.org/#/q/08685fb)), closes [#2272](https://jira.bytedance.com/browse/LKI-2272)
* **chat:** 优化密聊群组设置. ([168e8ed](https://review.byted.org/#/q/168e8ed)), closes [#1830](https://jira.bytedance.com/browse/LKI-1830)
* **chat:** 修复gif动画并添加post及inputView相关逻辑 ([8b1de13](https://review.byted.org/#/q/8b1de13)), closes [#2236](https://jira.bytedance.com/browse/LKI-2236)
* **chat:** 修复无法及时刷新群主信息以及撤回消息回复气泡不显示等问题 ([d0524b2](https://review.byted.org/#/q/d0524b2)), closes [#2246](https://jira.bytedance.com/browse/LKI-2246)
* **chat:** 修改撤回气泡逻辑 ([fa8f5ab](https://review.byted.org/#/q/fa8f5ab)), closes [#2217](https://jira.bytedance.com/browse/LKI-2217)
* **chat:** 完善feedback逻辑 ([f550eb5](https://review.byted.org/#/q/f550eb5)), closes [#2221](https://jira.bytedance.com/browse/LKI-2221)
* **chat:** 密聊倒计时抽取工具方法, 增加容错机制. ([1d15e64](https://review.byted.org/#/q/1d15e64)), closes [#2250](https://jira.bytedance.com/browse/LKI-2250)
* **chat:** 密聊回话去除翻译菜单 ([2df2c78](https://review.byted.org/#/q/2df2c78)), closes [#2283](https://jira.bytedance.com/browse/LKI-2283)
* **chat:** 暂时去掉 feed done 解散密聊操作; 同步 ntp 服务器时间操作. ([308121d](https://review.byted.org/#/q/308121d)), closes [#2259](https://jira.bytedance.com/browse/LKI-2259)
* **chat:** 更换earth图标,修复加载URL问题 ([c5d65d7](https://review.byted.org/#/q/c5d65d7)), closes [#2271](https://jira.bytedance.com/browse/LKI-2271)
* **chat:** 添加copy功能 ([b24a545](https://review.byted.org/#/q/b24a545)), closes [#2266](https://jira.bytedance.com/browse/LKI-2266)
* **chat:** 添加recallAction以及回复撤回消息气泡逻辑 ([ade463c](https://review.byted.org/#/q/ade463c)), closes [#2231](https://jira.bytedance.com/browse/LKI-2231)
* **chat:** 添加原文接口，完善翻译逻辑 ([cf4c813](https://review.byted.org/#/q/cf4c813)), closes [#2252](https://jira.bytedance.com/browse/LKI-2252)
* **chat:** 详情页支持翻译功能 ([104bb3a](https://review.byted.org/#/q/104bb3a)), closes [#2261](https://jira.bytedance.com/browse/LKI-2261)
* **component:** Lark日志收集,支持后端下发指令，客户端上传日志 ([2f544d9](https://review.byted.org/#/q/2f544d9)), closes [#2273](https://jira.bytedance.com/browse/LKI-2273)
* **component:** SessionExpiredPush新增加shouldDeleteAllData字段 收到这个字段时候，退出登录并清除本地所有文件 ([b1470e1](https://review.byted.org/#/q/b1470e1)), closes [#2256](https://jira.bytedance.com/browse/LKI-2256)
* **component:** 升级UI交互重构 ([7001b5f](https://review.byted.org/#/q/7001b5f)), closes [#2160](https://jira.bytedance.com/browse/LKI-2160)
* **component:** 升级UI交互重构 ([78dc26c](https://review.byted.org/#/q/78dc26c)), closes [#2160](https://jira.bytedance.com/browse/LKI-2160)
* **component:** 升级UI交互重构,修复PM测试的问题 ([c56ae73](https://review.byted.org/#/q/c56ae73)), closes [#2160](https://jira.bytedance.com/browse/LKI-2160)
* **component:** 升级UI交互重构,修复分割线显示错误 ([6965da5](https://review.byted.org/#/q/6965da5)), closes [#2160](https://jira.bytedance.com/browse/LKI-2160)
* **component:** 升级UI重构:修复badge不显示的问题 ([e9107f0](https://review.byted.org/#/q/e9107f0)), closes [#2160](https://jira.bytedance.com/browse/LKI-2160)
* **component:** 客户端升级接入新SDK服务,处理Source判定逻辑 ([6dc0523](https://review.byted.org/#/q/6dc0523)), closes [#2143](https://jira.bytedance.com/browse/LKI-2143)
* **component:** 导航demo增加Navibar ([7896f68](https://review.byted.org/#/q/7896f68)), closes [#2347](https://jira.bytedance.com/browse/LKI-2347)
* **component:** 抽离键盘 ([79a8c9c](https://review.byted.org/#/q/79a8c9c)), closes [#2362](https://jira.bytedance.com/browse/LKI-2362)
* **component:** 新版升级UI更改 feature gating 默认值为false ([dfe0613](https://review.byted.org/#/q/dfe0613)), closes [#2160](https://jira.bytedance.com/browse/LKI-2160)
* **feed:** feed 排序机制变更 ([57e9bea](https://review.byted.org/#/q/57e9bea)), closes [#2113](https://jira.bytedance.com/browse/LKI-2113)
* **message:** RichText迁移修改MessageDetail查看图片 ([8215170](https://review.byted.org/#/q/8215170)), closes [#2232](https://jira.bytedance.com/browse/LKI-2232)
* **message:** send doc add feature gating ([0bd7668](https://review.byted.org/#/q/0bd7668)), closes [#2314](https://jira.bytedance.com/browse/LKI-2314)
* **message:** 帖子图片添加 type ([0be6ac0](https://review.byted.org/#/q/0be6ac0)), closes [#2340](https://jira.bytedance.com/browse/LKI-2340)
* **message:** 应用applicationIconBadgeNum策略调整 ([333f2f6](https://review.byted.org/#/q/333f2f6)), closes [#2270](https://jira.bytedance.com/browse/LKI-2270)
* **message:** 添加会话发送文档消息埋点 ([47d9991](https://review.byted.org/#/q/47d9991)), closes [#2276](https://jira.bytedance.com/browse/LKI-2276)
* **message:** 表情国际化对接 ([b281b30](https://review.byted.org/#/q/b281b30)), closes [#2241](https://jira.bytedance.com/browse/LKI-2241)
* **message:** 设置密聊在线推送文案. ([61fa96c](https://review.byted.org/#/q/61fa96c)), closes [#2244](https://jira.bytedance.com/browse/LKI-2244)
* **message:** 跨租户通知 ([ea293a8](https://review.byted.org/#/q/ea293a8)), closes [#2226](https://jira.bytedance.com/browse/LKI-2226)
* **message:** 进退群系统消息通知配置 ([a9c7178](https://review.byted.org/#/q/a9c7178)), closes [#1862](https://jira.bytedance.com/browse/LKI-1862)
* **message:** 键盘发送文档 ([bea673c](https://review.byted.org/#/q/bea673c)), closes [#2225](https://jira.bytedance.com/browse/LKI-2225)
* **setting:** 系统设置页国际化文案位置调整, 增加图片国际化. ([aefe314](https://review.byted.org/#/q/aefe314)), closes [#2268](https://jira.bytedance.com/browse/LKI-2268)
* **share:** 优化ShareExtension多语言方案，使用系统方案 ([ae3a8de](https://review.byted.org/#/q/ae3a8de)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)
* **share:** 使用PromisesKit重写数据处理逻辑 ([2b49c95](https://review.byted.org/#/q/2b49c95)), closes [#2328](https://jira.bytedance.com/browse/LKI-2328)
* **share:** 使用RxSwift 替换 PromisesKit重写数据处理逻辑 ([8006d13](https://review.byted.org/#/q/8006d13)), closes [#2328](https://jira.bytedance.com/browse/LKI-2328)
* **share:** 处理登录退出不能及时响应的问题 ([1651295](https://review.byted.org/#/q/1651295)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)



<a name="1.8.0"></a>
# 1.8.0 (2018-07-13)


### Bug Fixes

* **all:** Lark.iOS CI编译问题修复 ([e258c14](https://review.byted.org/#/q/e258c14)), closes [#2017](https://jira.bytedance.com/browse/LKI-2017)
* **all:** 启动引导图资源、文案替换 ([2d02a42](https://review.byted.org/#/q/2d02a42)), closes [#2059](https://jira.bytedance.com/browse/LKI-2059)
* **chat:** 修复和优化密聊 UI 走查问题. ([b29860d](https://review.byted.org/#/q/b29860d)), closes [#2047](https://jira.bytedance.com/browse/LKI-2047)
* **chat:** 修复拨打电话无效的问题. ([716968d](https://review.byted.org/#/q/716968d)), closes [#2185](https://jira.bytedance.com/browse/LKI-2185)
* **chat:** 修改SyncMessaegToolBar的崩溃， ([91ce59a](https://review.byted.org/#/q/91ce59a)), closes [#2081](https://jira.bytedance.com/browse/LKI-2081)
* **chat:** 修正chatvc左上角未读数不显示的问题 ([b8ab064](https://review.byted.org/#/q/b8ab064)), closes [#2151](https://jira.bytedance.com/browse/LKI-2151)
* **chat:** 修正退群后导航逻辑 ([d87c6c2](https://review.byted.org/#/q/d87c6c2)), closes [#2195](https://jira.bytedance.com/browse/LKI-2195)
* **chat:** 单聊建群时，点击提示气泡奔溃 ([329dc2c](https://review.byted.org/#/q/329dc2c)), closes [#1954](https://jira.bytedance.com/browse/LKI-1954)
* **chat:** 开放跨租户Bot入口，引导页 ([f58ac6e](https://review.byted.org/#/q/f58ac6e)), closes [#1924](https://jira.bytedance.com/browse/LKI-1924)
* **component:** bug：LKI-2096。切换账号后进入docs，看到还是前一个账户的列表的问题。 ([4348c02](https://review.byted.org/#/q/4348c02))
* **component:** larkrustclient weak对象强取crash ([b674803](https://review.byted.org/#/q/b674803)), closes [#1957](https://jira.bytedance.com/browse/LKI-1957)
* **component:** 修改container.resolve方法崩溃，修改成为同步resolve ([778019d](https://review.byted.org/#/q/778019d)), closes [#2082](https://jira.bytedance.com/browse/LKI-2082)
* **component:** 升级 埋点 ([fac27b6](https://review.byted.org/#/q/fac27b6)), closes [#2138](https://jira.bytedance.com/browse/LKI-2138)
* **component:** 更新DocsSDK，1.7.8；调整DocsViewControllerFactory.dependency赋值，取消异步解决回调强解optional崩溃。 ([96aec0b](https://review.byted.org/#/q/96aec0b))
* **component:** 更新EEMicroAppSDK ([f460cd6](https://review.byted.org/#/q/f460cd6)), closes [#2095](https://jira.bytedance.com/browse/LKI-2095)
* **component:** 查看大图在横屏模式下无法双击放大 ([6ed1afd](https://review.byted.org/#/q/6ed1afd)), closes [#1950](https://jira.bytedance.com/browse/LKI-1950)
* **component:** 租户新手引导增加专属客服的引导 ([9267ee2](https://review.byted.org/#/q/9267ee2)), closes [#2033](https://jira.bytedance.com/browse/LKI-2033) [#2034](https://jira.bytedance.com/browse/LKI-2034)
* **component:** 跳转逻辑错误 ([3d34e2d](https://review.byted.org/#/q/3d34e2d)), closes [#2207](https://jira.bytedance.com/browse/LKI-2207)
* **component:** 部分文案国际化 ([2d9292c](https://review.byted.org/#/q/2d9292c)), closes [#2127](https://jira.bytedance.com/browse/LKI-2127)
* **component:** 部分文案国际化 ([ebe2749](https://review.byted.org/#/q/ebe2749)), closes [#2127](https://jira.bytedance.com/browse/LKI-2127)
* **contact:** 修改群设置中，搜人，添加，循环引用问题。 ([2d53e47](https://review.byted.org/#/q/2d53e47)), closes [#2016](https://jira.bytedance.com/browse/LKI-2016)
* **docs:** 处理 重复添加Docs.from ([aa14f7d](https://review.byted.org/#/q/aa14f7d)), closes [#2008](https://jira.bytedance.com/browse/LKI-2008)
* **docs:** 处理 重复添加Docs.from 参数独立编码 ([1b54b53](https://review.byted.org/#/q/1b54b53)), closes [#2008](https://jira.bytedance.com/browse/LKI-2008)
* **docs:** 处理 重复添加Docs.from 参数独立编码 ([1b7419b](https://review.byted.org/#/q/1b7419b)), closes [#2008](https://jira.bytedance.com/browse/LKI-2008)
* **email:** 修复撤回邮件无草稿的BUG ([896ffc0](https://review.byted.org/#/q/896ffc0)), closes [#2190](https://jira.bytedance.com/browse/LKI-2190)
* **email:** 修复新邮件文案 ([6887c6f](https://review.byted.org/#/q/6887c6f)), closes [#2085](https://jira.bytedance.com/browse/LKI-2085)
* **email:** 修复邮件快捷回复按键位置BUG ([7028ebb](https://review.byted.org/#/q/7028ebb)), closes [#2183](https://jira.bytedance.com/browse/LKI-2183)
* **email:** 修复邮件无法一次拉取的问题 ([de61212](https://review.byted.org/#/q/de61212)), closes [#2058](https://jira.bytedance.com/browse/LKI-2058)
* **email:** 邮件菜单失效 ([2dffc10](https://review.byted.org/#/q/2dffc10)), closes [#2167](https://jira.bytedance.com/browse/LKI-2167)
* **feed:** done里的Feed显示时间为LastMessage的时间 ([558a45d](https://review.byted.org/#/q/558a45d)), closes [#2067](https://jira.bytedance.com/browse/LKI-2067)
* **feed:** 同步会话最近20条消息阻塞Feed同步线程的问题 ([1b7daf4](https://review.byted.org/#/q/1b7daf4)), closes [#2053](https://jira.bytedance.com/browse/LKI-2053)
* **feed:** 埋点 chat_done 的参数badget 名字错了，应该改为 badge ([c56ac6b](https://review.byted.org/#/q/c56ac6b)), closes [#1997](https://jira.bytedance.com/browse/LKI-1997)
* **feed:** 未知消息英文下，feed预览没有国际化 ([b289c6b](https://review.byted.org/#/q/b289c6b)), closes [#2140](https://jira.bytedance.com/browse/LKI-2140)
* **feed:** 过滤器选择done的时候，inbox前面的图标没有了 ([5fc4dcc](https://review.byted.org/#/q/5fc4dcc)), closes [#2189](https://jira.bytedance.com/browse/LKI-2189)
* **login:** 新手引导图字体、按钮隐藏不对 ([60a3c78](https://review.byted.org/#/q/60a3c78)), closes [#2094](https://jira.bytedance.com/browse/LKI-2094)
* **message:** (1)实现vote转发/加急确认样式 (2)键盘中去掉拍照入口 (3)requestChatByUserId pack User (4)投票键盘弹出遮挡消息 ([ac9a7e1](https://review.byted.org/#/q/ac9a7e1)), closes [#2072](https://jira.bytedance.com/browse/LKI-2072)
* **message:** @Bot还有绿点已读未读的状态展示 ([52b5a5f](https://review.byted.org/#/q/52b5a5f)), closes [#2057](https://jira.bytedance.com/browse/LKI-2057)
* **message:** chatds中append/insert加入数据检查逻辑 ([9ae817b](https://review.byted.org/#/q/9ae817b)), closes [#2126](https://jira.bytedance.com/browse/LKI-2126)
* **message:** closes [#2203](https://jira.bytedance.com/browse/LKI-2203) ([e7cc1dd](https://review.byted.org/#/q/e7cc1dd))
* **message:** fix some ui style ([206085f](https://review.byted.org/#/q/206085f)), closes [#2077](https://jira.bytedance.com/browse/LKI-2077)
* **message:** messageDetail and email wknavigationdeletage未设置禁止跳转bug ([f6ddccb](https://review.byted.org/#/q/f6ddccb)), closes [#2104](https://jira.bytedance.com/browse/LKI-2104)
* **message:** reaction/docpreview打点找回，重实现 ([cd31369](https://review.byted.org/#/q/cd31369)), closes [#2156](https://jira.bytedance.com/browse/LKI-2156)
* **message:** update message-detail ([4952874](https://review.byted.org/#/q/4952874)), closes [#2025](https://jira.bytedance.com/browse/LKI-2025)
* 修复编译不过的问题 ([bcd7fd1](https://review.byted.org/#/q/bcd7fd1))
* **message:** update Vote UI style really not important ([0ebf2bb](https://review.byted.org/#/q/0ebf2bb)), closes [#2077](https://jira.bytedance.com/browse/LKI-2077)
* **message:** Vote bug fix ([8d9ffe6](https://review.byted.org/#/q/8d9ffe6)), closes [#2025](https://jira.bytedance.com/browse/LKI-2025)
* **message:** vote footerLabel 高度优先级过低导致... ([92a8990](https://review.byted.org/#/q/92a8990)), closes [#2036](https://jira.bytedance.com/browse/LKI-2036)
* **message:** Vote lineWidth 1 => 0.5 ([0949524](https://review.byted.org/#/q/0949524)), closes [#2077](https://jira.bytedance.com/browse/LKI-2077)
* **message:** Vote UI bug ([c464769](https://review.byted.org/#/q/c464769)), closes [#2077](https://jira.bytedance.com/browse/LKI-2077)
* **message:** voteCardView 多选无法多选bugfix ([b97f6b1](https://review.byted.org/#/q/b97f6b1)), closes [#2025](https://jira.bytedance.com/browse/LKI-2025)
* **message:** VoteCardView多行title导致高度无法完全撑开 ([e39d092](https://review.byted.org/#/q/e39d092)), closes [#2063](https://jira.bytedance.com/browse/LKI-2063)
* **message:** 会话内连接重连后，离线消息上屏 ([912baf8](https://review.byted.org/#/q/912baf8)), closes [#2118](https://jira.bytedance.com/browse/LKI-2118)
* **message:** 修复replyView 显示的问题. ([d9437dc](https://review.byted.org/#/q/d9437dc)), closes [#1861](https://jira.bytedance.com/browse/LKI-1861)
* **message:** 修改投票卡片国际化文案 ([9fef834](https://review.byted.org/#/q/9fef834)), closes [#1920](https://jira.bytedance.com/browse/LKI-1920)
* **message:** 修正合并转发消息选择页用户名不显示的问题 ([777ff14](https://review.byted.org/#/q/777ff14)), closes [#2187](https://jira.bytedance.com/browse/LKI-2187)
* **message:** 修正转发相关传参错误 ([c068bc7](https://review.byted.org/#/q/c068bc7)), closes [#2181](https://jira.bytedance.com/browse/LKI-2181)
* **message:** 合并转发选择时消息遮挡问题 ([609bf56](https://review.byted.org/#/q/609bf56)), closes [#2122](https://jira.bytedance.com/browse/LKI-2122)
* **message:** 安卓发语音无法播放 ([042a1da](https://review.byted.org/#/q/042a1da)), closes [#2203](https://jira.bytedance.com/browse/LKI-2203)
* **message:** 群分享消息Chat缺失时，上层pack处理 ([1c1b560](https://review.byted.org/#/q/1c1b560)), closes [#2014](https://jira.bytedance.com/browse/LKI-2014)
* **message:** 解决锁屏后，第一条收到的消息可能会自动已读的问题 ([8871450](https://review.byted.org/#/q/8871450)), closes [#1932](https://jira.bytedance.com/browse/LKI-1932)
* **mine:** 当前在线设备数统计 不显示了 ([4275f23](https://review.byted.org/#/q/4275f23)), closes [#2071](https://jira.bytedance.com/browse/LKI-2071)
* **search:** 修改SearchTableViewCell infoLabel布局 ([ec22849](https://review.byted.org/#/q/ec22849)), closes [#2108](https://jira.bytedance.com/browse/LKI-2108)
* **search:** 修改搜索中月份错误的问题 ([591b1b7](https://review.byted.org/#/q/591b1b7)), closes [#2201](https://jira.bytedance.com/browse/LKI-2201)
* **search:** 修改搜索和feed页面中时间显示的格式 ([6a732a5](https://review.byted.org/#/q/6a732a5)), closes [#2086](https://jira.bytedance.com/browse/LKI-2086)
* **search:** 修改搜索结果页面，显示搜索错误的问题 ([af92479](https://review.byted.org/#/q/af92479)), closes [#2093](https://jira.bytedance.com/browse/LKI-2093)
* **voip:** 修复 bundle 错误引起的崩溃 ([cf39b9a](https://review.byted.org/#/q/cf39b9a)), closes [#2188](https://jira.bytedance.com/browse/LKI-2188)
* 修改feature gating的key ([7331bb7](https://review.byted.org/#/q/7331bb7))
* 日历卡片消息国际化 ([6bc3dba](https://review.byted.org/#/q/6bc3dba))
* 根据从视图页or从详情页进入来判断是否显示chat ([3be06d8](https://review.byted.org/#/q/3be06d8))
* **voip:** 修复 voip 问题 ([62671ec](https://review.byted.org/#/q/62671ec)), closes [#2054](https://jira.bytedance.com/browse/LKI-2054)
* **web:** 监听用户信号变化信号使用不对 ([eef714d](https://review.byted.org/#/q/eef714d)), closes [#2096](https://jira.bytedance.com/browse/LKI-2096)
* **web:** 识别二维码失效 ([339ab8c](https://review.byted.org/#/q/339ab8c)), closes [#2191](https://jira.bytedance.com/browse/LKI-2191)


### Features

* **all:** 修改权限请求文案 ([d9e68c3](https://review.byted.org/#/q/d9e68c3)), closes [#2003](https://jira.bytedance.com/browse/LKI-2003)
* **chat:** chat 中密聊消息销毁动画. ([47f625f](https://review.byted.org/#/q/47f625f)), closes [#2047](https://jira.bytedance.com/browse/LKI-2047)
* **chat:** feed 页密聊会话展示增加 icon, 描述信息为"收到一条加密消息". ([aed2d70](https://review.byted.org/#/q/aed2d70)), closes [#2038](https://jira.bytedance.com/browse/LKI-2038)
* **chat:** 修复密聊 UI 走查列表中的问题. ([05df6d5](https://review.byted.org/#/q/05df6d5)), closes [#1830](https://jira.bytedance.com/browse/LKI-1830)
* **chat:** 创建会话增加密聊参数. ([1e47936](https://review.byted.org/#/q/1e47936)), closes [#2043](https://jira.bytedance.com/browse/LKI-2043)
* **chat:** 增加对密聊的 featureGating 选项. ([b50f66f](https://review.byted.org/#/q/b50f66f)), closes [#2045](https://jira.bytedance.com/browse/LKI-2045)
* **chat:** 完善UI，添加了部分简单逻辑 ([34638d4](https://review.byted.org/#/q/34638d4)), closes [#2192](https://jira.bytedance.com/browse/LKI-2192)
* **chat:** 添加translate部分逻辑 ([4882eab](https://review.byted.org/#/q/4882eab)), closes [#2200](https://jira.bytedance.com/browse/LKI-2200)
* **chat:** 添加群主撤回消息功能 ([29a0ec1](https://review.byted.org/#/q/29a0ec1)), closes [#2213](https://jira.bytedance.com/browse/LKI-2213)
* **chat:** 添加翻译反馈弹窗、翻译语言设置 ([f74c489](https://review.byted.org/#/q/f74c489)), closes [#2177](https://jira.bytedance.com/browse/LKI-2177)
* **chat:** 添加设置逻辑 ([f03579d](https://review.byted.org/#/q/f03579d)), closes [#2208](https://jira.bytedance.com/browse/LKI-2208)
* **component:** navigationservice和tabbarservice合并 ([24ec3b7](https://review.byted.org/#/q/24ec3b7)), closes [#2158](https://jira.bytedance.com/browse/LKI-2158)
* **component:** 键盘使用 key 作为标识 ([5f0349d](https://review.byted.org/#/q/5f0349d)), closes [#2182](https://jira.bytedance.com/browse/LKI-2182)
* **docs:** openlink针对Doc添加from ([85147e0](https://review.byted.org/#/q/85147e0))
* **docs:** 调整docs链接中的from参数值 ([619a11e](https://review.byted.org/#/q/619a11e)), closes [#2149](https://jira.bytedance.com/browse/LKI-2149)
* **email:** 创建群中搜索人或群接口迁移到IntegrationSearch ([7b1c3a7](https://review.byted.org/#/q/7b1c3a7)), closes [#2152](https://jira.bytedance.com/browse/LKI-2152)
* **email:** 邮件添加成员接口迁移到IntegrationSearch ([0960904](https://review.byted.org/#/q/0960904)), closes [#2147](https://jira.bytedance.com/browse/LKI-2147)
* **favorite:** (1)抽离mergeMessage详情页面 (2)图片浏览/展示消息时间3段公共逻辑抽取 ([aaf167c](https://review.byted.org/#/q/aaf167c)), closes [#1969](https://jira.bytedance.com/browse/LKI-1969)
* **favorite:** Favorite api ([a1640b2](https://review.byted.org/#/q/a1640b2)), closes [#1984](https://jira.bytedance.com/browse/LKI-1984)
* **favorite:** init favorite ([1e69bd3](https://review.byted.org/#/q/1e69bd3)), closes [#1987](https://jira.bytedance.com/browse/LKI-1987)
* **favorite:** Menu添加收藏功能 ([409a590](https://review.byted.org/#/q/409a590)), closes [#1964](https://jira.bytedance.com/browse/LKI-1964)
* **favorite:** MineMain添加favorite_item ([6f7d7c4](https://review.byted.org/#/q/6f7d7c4)), closes [#1964](https://jira.bytedance.com/browse/LKI-1964)
* **favorite:** 增加未知消息cell ([9308f8e](https://review.byted.org/#/q/9308f8e)), closes [#2006](https://jira.bytedance.com/browse/LKI-2006)
* **favorite:** 对接收藏真实数据 ([f4680c0](https://review.byted.org/#/q/f4680c0)), closes [#2012](https://jira.bytedance.com/browse/LKI-2012)
* **favorite:** 接入 favorite model ([36ef942](https://review.byted.org/#/q/36ef942)), closes [#1986](https://jira.bytedance.com/browse/LKI-1986)
* **favorite:** 收藏cell的action ([6657e01](https://review.byted.org/#/q/6657e01)), closes [#2002](https://jira.bytedance.com/browse/LKI-2002)
* **favorite:** 收藏接口国际化 ([b0f147f](https://review.byted.org/#/q/b0f147f)), closes [#2011](https://jira.bytedance.com/browse/LKI-2011)
* **favorite:** 收藏详情cell框架 ([b45dd40](https://review.byted.org/#/q/b45dd40)), closes [#2000](https://jira.bytedance.com/browse/LKI-2000)
* **favorite:** 收藏详情页VC框架 ([e34f775](https://review.byted.org/#/q/e34f775)), closes [#1966](https://jira.bytedance.com/browse/LKI-1966)
* **favorite:** 收藏详情页壳vc nav导航栏完成 ([a09892d](https://review.byted.org/#/q/a09892d)), closes [#1999](https://jira.bytedance.com/browse/LKI-1999)
* **favorite:** 收藏页请求及封装 ([d452b6c](https://review.byted.org/#/q/d452b6c)), closes [#2007](https://jira.bytedance.com/browse/LKI-2007)
* **favorite:** 添加 favorite render ([68269a8](https://review.byted.org/#/q/68269a8)), closes [#1998](https://jira.bytedance.com/browse/LKI-1998)
* **favorite:** 添加FavoriteAction以及Mine的跳转 ([9e1ff59](https://review.byted.org/#/q/9e1ff59)), closes [#2009](https://jira.bytedance.com/browse/LKI-2009)
* **favorite:** 详情页支持收藏 ([18526e9](https://review.byted.org/#/q/18526e9)), closes [#2150](https://jira.bytedance.com/browse/LKI-2150)
* **favorite:** 语音收藏相关 ([6309727](https://review.byted.org/#/q/6309727)), closes [#1976](https://jira.bytedance.com/browse/LKI-1976)
* **favorite:** 语音消息 cell ([cfdde7e](https://review.byted.org/#/q/cfdde7e)), closes [#1975](https://jira.bytedance.com/browse/LKI-1975)
* **feed:** feed 新增埋点相关 ([a637e69](https://review.byted.org/#/q/a637e69)), closes [#2138](https://jira.bytedance.com/browse/LKI-2138) [#2142](https://jira.bytedance.com/browse/LKI-2142)
* **feed:** feed 过滤器埋点 ([3ba0c01](https://review.byted.org/#/q/3ba0c01)), closes [#2021](https://jira.bytedance.com/browse/LKI-2021)
* **feed:** include draft mail for feed card filter ([e605210](https://review.byted.org/#/q/e605210)), closes [#1955](https://jira.bytedance.com/browse/LKI-1955)
* **feed:** 被踢出群，或者群解散后，在feed页点击就直接弹框提示已被移除，不进入到会话内再提示 ([e8d7055](https://review.byted.org/#/q/e8d7055)), closes [#1947](https://jira.bytedance.com/browse/LKI-1947)
* **file:** 修改本地选择文件最大尺寸限制 ([ab57b33](https://review.byted.org/#/q/ab57b33)), closes [#2157](https://jira.bytedance.com/browse/LKI-2157)
* **message:** chat 中密聊已读开始显示倒计时, 倒计时结束销毁密聊消息. ([d23e979](https://review.byted.org/#/q/d23e979)), closes [#2040](https://jira.bytedance.com/browse/LKI-2040)
* **message:** feed 增加密聊过滤器. ([3c5fd79](https://review.byted.org/#/q/3c5fd79)), closes [#1830](https://jira.bytedance.com/browse/LKI-1830)
* **message:** richtext 兼容 emotion ([ae426f0](https://review.byted.org/#/q/ae426f0)), closes [#2171](https://jira.bytedance.com/browse/LKI-2171)
* **message:** 会议会话内相关打点及一些丢失打点逻辑找回 ([b49ad35](https://review.byted.org/#/q/b49ad35)), closes [#2156](https://jira.bytedance.com/browse/LKI-2156)
* **message:** 使用 richtext 方式发送 文本/贴子 ([26249db](https://review.byted.org/#/q/26249db)), closes [#2124](https://jira.bytedance.com/browse/LKI-2124)
* **message:** 兼容两种 RichText at content ([df58177](https://review.byted.org/#/q/df58177)), closes [#2179](https://jira.bytedance.com/browse/LKI-2179)
* **message:** 加密消息不显示转发菜单; 密聊消息完成焚毁流程. ([ab58c43](https://review.byted.org/#/q/ab58c43)), closes [#1830](https://jira.bytedance.com/browse/LKI-1830)
* **message:** 单聊建群要支持选择语音 ([0d683c4](https://review.byted.org/#/q/0d683c4)), closes [#1946](https://jira.bytedance.com/browse/LKI-1946)
* **message:** 合并图片/拍照入口 ([4fece69](https://review.byted.org/#/q/4fece69)), closes [#1914](https://jira.bytedance.com/browse/LKI-1914)
* **message:** 合并转发支持[群名片],[文件]消息. ([dd739f7](https://review.byted.org/#/q/dd739f7)), closes [#1992](https://jira.bytedance.com/browse/LKI-1992)
* **message:** 合并转发的消息支持回复. ([f68ec72](https://review.byted.org/#/q/f68ec72)), closes [#2004](https://jira.bytedance.com/browse/LKI-2004)
* **message:** 增加密聊消息功能. ([dac210e](https://review.byted.org/#/q/dac210e)), closes [#1830](https://jira.bytedance.com/browse/LKI-1830)
* **message:** 对接转发新接口 ([ad67d0b](https://review.byted.org/#/q/ad67d0b)), closes [#1967](https://jira.bytedance.com/browse/LKI-1967)
* **message:** 投票接入卡片消息 ([7878347](https://review.byted.org/#/q/7878347)), closes [#1920](https://jira.bytedance.com/browse/LKI-1920)
* **message:** 撤回消息可用性由服务端动态控制 ([92cebeb](https://review.byted.org/#/q/92cebeb)), closes [#2198](https://jira.bytedance.com/browse/LKI-2198)
* **message:** 收藏列表/详情页, text, post cell 展示, 下沉必要逻辑. ([3f9e2f8](https://review.byted.org/#/q/3f9e2f8)), closes [#1973](https://jira.bytedance.com/browse/LKI-1973)
* **message:** 收藏列表增加合并转发 cell; 下沉解析 richText 逻辑. ([2a40652](https://review.byted.org/#/q/2a40652)), closes [#1983](https://jira.bytedance.com/browse/LKI-1983)
* **message:** 消息添加来源 ([694df7c](https://review.byted.org/#/q/694df7c)), closes [#2097](https://jira.bytedance.com/browse/LKI-2097)
* **message:** 消息转发禁止转发到密聊chat 中, 密聊中消息也不能转发. ([7748f64](https://review.byted.org/#/q/7748f64)), closes [#2148](https://jira.bytedance.com/browse/LKI-2148)
* **message:** 详情页根合并转发消息对接点击事件 ([ac90ccf](https://review.byted.org/#/q/ac90ccf)), closes [#1958](https://jira.bytedance.com/browse/LKI-1958)
* **message:** 销毁时间校准, 更新 ntp 时间. ([5b58408](https://review.byted.org/#/q/5b58408)), closes [#2048](https://jira.bytedance.com/browse/LKI-2048)
* **mine:** 添加个人状态打点 ([a3be8a7](https://review.byted.org/#/q/a3be8a7)), closes [#2168](https://jira.bytedance.com/browse/LKI-2168)
* **search:** smartSearch迁移到IntegrationSearch ([dc21c9c](https://review.byted.org/#/q/dc21c9c)), closes [#2134](https://jira.bytedance.com/browse/LKI-2134)
* **search:** 创建群场景配合搜索接口迁移，数据结构调整一下 ([c69343d](https://review.byted.org/#/q/c69343d)), closes [#2152](https://jira.bytedance.com/browse/LKI-2152)
* **setting:** App启动后同步一次服务器ntp时间, 优化销毁动画. ([495a81c](https://review.byted.org/#/q/495a81c)), closes [#2199](https://jira.bytedance.com/browse/LKI-2199)
* **setting:** 修复个人资料页状态, 英文被压缩的问题. ([eddccff](https://review.byted.org/#/q/eddccff)), closes [#2127](https://jira.bytedance.com/browse/LKI-2127)
* **setting:** 增加 staging 环境. ([df450a7](https://review.byted.org/#/q/df450a7)), closes [#2197](https://jira.bytedance.com/browse/LKI-2197)
* **share:** add  public protocol ShareExtensionConfigProtocol ([1f8ddc0](https://review.byted.org/#/q/1f8ddc0)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)
* **share:** shareExtension 支持多语言 ([5803e9d](https://review.byted.org/#/q/5803e9d)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)
* **share:** shareextension图片视频和文件的展示 ([42e7095](https://review.byted.org/#/q/42e7095)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)
* **share:** 优化ShareExtension共享数据结构 ([1823ef8](https://review.byted.org/#/q/1823ef8)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)
* **share:** 保存分项数据到共享目录 ([4099797](https://review.byted.org/#/q/4099797)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)
* **share:** 修复分享多选人问题、添加ShareExtension代码文档，去掉多余的Type定义，复用ItemType ([9a13e35](https://review.byted.org/#/q/9a13e35)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)
* **share:** 修改选人界面取消逻辑，添加混合Item的处理 ([1ca724f](https://review.byted.org/#/q/1ca724f)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)
* **share:** 分享实现打开主App,并读取共享数据 ([cf7360c](https://review.byted.org/#/q/cf7360c)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)
* 修改会议功能feature gating的key ([5789425](https://review.byted.org/#/q/5789425))
* **share:** 分享支持多语言 ([e50a573](https://review.byted.org/#/q/e50a573)), closes [#2106](https://jira.bytedance.com/browse/LKI-2106)
* **share:** 创建 Target: shareExtension ([11ce023](https://review.byted.org/#/q/11ce023)), closes [#1066](https://jira.bytedance.com/browse/LKI-1066)
* **share:** 创建Lark & shareExtension 共享库 ([3ee2dbb](https://review.byted.org/#/q/3ee2dbb)), closes [#2107](https://jira.bytedance.com/browse/LKI-2107)
* **share:** 创建共享的数据Model & 增加共享的Config属性 ([59c92aa](https://review.byted.org/#/q/59c92aa)), closes [#2107](https://jira.bytedance.com/browse/LKI-2107)
* **share:** 删除多余的类型检查代码，添加启动时分享数据类型、size、count的检查，修改启动检查顺序 ([a0400cc](https://review.byted.org/#/q/a0400cc)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)
* **share:** 埋点: 系统分享 ([b77a21a](https://review.byted.org/#/q/b77a21a)), closes [#2139](https://jira.bytedance.com/browse/LKI-2139)
* **share:** 处理FIleUrl特殊case，添加数据读取出错Alert ([3c21c20](https://review.byted.org/#/q/3c21c20)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)
* **share:** 支持头条圈小程序链接分享到Lark会话内 ([a15886c](https://review.byted.org/#/q/a15886c)), closes [#2115](https://jira.bytedance.com/browse/LKI-2115)
* **share:** 文本和URL的分享显示 ([b21b23b](https://review.byted.org/#/q/b21b23b)), closes [#2144](https://jira.bytedance.com/browse/LKI-2144)
* **share:** 添加动态属性，优化Item解析，优化UI显示 ([27ed081](https://review.byted.org/#/q/27ed081)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)
* **share:** 系统分享基本功能完成 ([0c11933](https://review.byted.org/#/q/0c11933)), closes [#2101](https://jira.bytedance.com/browse/LKI-2101)
* **voip:** 更新最新的 voip 且变更电话触发方式 ([e6e85c2](https://review.byted.org/#/q/e6e85c2)), closes [#1919](https://jira.bytedance.com/browse/LKI-1919)
* **voip:** 添加voip系统消息 ([baf61e7](https://review.byted.org/#/q/baf61e7)), closes [#1993](https://jira.bytedance.com/browse/LKI-1993)
* **web:** 调整JSSDK结构 ([28a5b47](https://review.byted.org/#/q/28a5b47)), closes [#2055](https://jira.bytedance.com/browse/LKI-2055) [#2051](https://jira.bytedance.com/browse/LKI-2051) [#2052](https://jira.bytedance.com/browse/LKI-2052)
* feed 会议添加(无主题)显示及国际化 ([86b96ef](https://review.byted.org/#/q/86b96ef))
* 接入通知接口 ([2023bed](https://review.byted.org/#/q/2023bed))
* 更改feature gating接口 ([a0d8174](https://review.byted.org/#/q/a0d8174))
* 添加会议的feature gating ([c49baf0](https://review.byted.org/#/q/c49baf0))



<a name="1.6.0"></a>
# 1.6.0 (2018-06-11)


### Bug Fixes

* **chat:** 修复云盘文件中，空文件夹显示的问题 ([505cb6a](https://review.byted.org/#/q/505cb6a)), closes [#1949](https://jira.bytedance.com/browse/LKI-1949)
* **chat:** 修复单聊建群的小问题 ([924d89e](https://review.byted.org/#/q/924d89e)), closes [#1916](https://jira.bytedance.com/browse/LKI-1916) [#1921](https://jira.bytedance.com/browse/LKI-1921) [#1923](https://jira.bytedance.com/browse/LKI-1923)
* **chat:** 修复菜单闪退BUG ([86cc1cd](https://review.byted.org/#/q/86cc1cd)), closes [#1927](https://jira.bytedance.com/browse/LKI-1927)
* **chatinfo:** 群成员排序中，群主排首位，但群主也需要展示在下方字母序里 ([49fd46e](https://review.byted.org/#/q/49fd46e)), closes [#1941](https://jira.bytedance.com/browse/LKI-1941)
* **chatInfo:** 修复添加群成员按钮显示判断逻辑，优化页面刷新逻辑 ([034e796](https://review.byted.org/#/q/034e796))
* **feed:** feed 列表 At  不消失的问题 ([ab1d0a5](https://review.byted.org/#/q/ab1d0a5)), closes [#666](https://jira.bytedance.com/browse/LKI-666)
* **message:** (发版后合并) 合并转发消息24小时后不应能撤回 ([b314a90](https://review.byted.org/#/q/b314a90)), closes [#1917](https://jira.bytedance.com/browse/LKI-1917)
* **message:** 一些文案修正 ([81e3d3f](https://review.byted.org/#/q/81e3d3f)), closes [#1913](https://jira.bytedance.com/browse/LKI-1913) [#1895](https://jira.bytedance.com/browse/LKI-1895) [#1894](https://jira.bytedance.com/browse/LKI-1894) [#1888](https://jira.bytedance.com/browse/LKI-1888)
* **message:** 修复消息 cell 展示不全时显示时间跳动的问题. ([d070664](https://review.byted.org/#/q/d070664)), closes [#1878](https://jira.bytedance.com/browse/LKI-1878)
* **message:** 加急被确认在不显示详情设置下push文案调整 ([36eb4e5](https://review.byted.org/#/q/36eb4e5)), closes [#1894](https://jira.bytedance.com/browse/LKI-1894)
* **message:** 隐私模式下不显示群名称 ([14d44da](https://review.byted.org/#/q/14d44da)), closes [#1933](https://jira.bytedance.com/browse/LKI-1933)
* **QRCodeViewController:** Lark扫码打开外部浏览器Crash ([6cca621](https://review.byted.org/#/q/6cca621))
* 修复错误的字段以显示重复性规则 ([ce1fa1e](https://review.byted.org/#/q/ce1fa1e))
* 添加MessageDetailViewController的log方法 ([7cff1c1](https://review.byted.org/#/q/7cff1c1))
* **web:** 头条圈发帖时没有显示发表按钮。从doc分享到头条圈，没有发表按钮 ([6fa6bcd](https://review.byted.org/#/q/6fa6bcd)), closes [#1912](https://jira.bytedance.com/browse/LKI-1912)
* **web:** 头条圈访问打点偏少. ([c47ba77](https://review.byted.org/#/q/c47ba77)), closes [#1921](https://jira.bytedance.com/browse/LKI-1921)
* **web:** 应用中心值班号点击无法跳转会话 ([35361fd](https://review.byted.org/#/q/35361fd)), closes [#1902](https://jira.bytedance.com/browse/LKI-1902)


### Features

* calendar update version tp 1.2.25 ([f5f49a4](https://review.byted.org/#/q/f5f49a4))
* calendarBot卡片背景色调为白色 ([18a214d](https://review.byted.org/#/q/18a214d))
* **calendar:** 解决跨越0点时视图布局错乱的问题 ([eac8d9f](https://review.byted.org/#/q/eac8d9f))
* **feed:** add feed card filter and hide this for not bytedancers ([a20d1ba](https://review.byted.org/#/q/a20d1ba))
* **feed:** adjust feed filter ui and i18n ([561cefd](https://review.byted.org/#/q/561cefd))
* **message:** 优化富文本发图体验 ([fffd3b1](https://review.byted.org/#/q/fffd3b1)), closes [#1926](https://jira.bytedance.com/browse/LKI-1926)
* **message:** 长消息显示时间时滚动到 cell 底部. ([3707114](https://review.byted.org/#/q/3707114)), closes [#1878](https://jira.bytedance.com/browse/LKI-1878)
* 单聊Bot去掉已读，去掉Bot加急 ([c7e13c1](https://review.byted.org/#/q/c7e13c1))
* 日历1.2.18上车 ([b8a1018](https://review.byted.org/#/q/b8a1018))


### BREAKING CHANGES

* **feed:** closes #1846, #1694

Change-Id: I36753de71c35232c02f3719caf73062d4fc2fd6f
* **feed:** closes #1846, #1694

Change-Id: I339ca75a1f5695c8231a43cb413d21e97144e794



<a name="1.5.1"></a>
## 1.5.1 (2018-05-28)


### Bug Fixes

* **group info:** 修复非群主不能加人 ([dff5204](https://review.byted.org/#/q/dff5204)), closes [#1906](https://jira.bytedance.com/browse/LKI-1906)
* **group setting:** 仅群主可分享的文案有问题，需要修改 ([915f427](https://review.byted.org/#/q/915f427)), closes [#1909](https://jira.bytedance.com/browse/LKI-1909)



<a name="1.5.0"></a>
# 1.5.0 (2018-05-24)


### Bug Fixes

* **component:** 修复 URL 代理崩溃问题 ([dfcdf18](https://review.byted.org/#/q/dfcdf18)), closes [#1858](https://jira.bytedance.com/browse/LKI-1858)
* **contact:** iOS 10上进入值班号和机器人页面崩溃，设置头像可能错乱 ([7c3a63f](https://review.byted.org/#/q/7c3a63f)), closes [#1868](https://jira.bytedance.com/browse/LKI-1868)
* **group info:** 拼接头像在群设置页点开大图，没有显示出拼接头像(https://jira.bytedance.com/browse/LKI-1897) ([cedda88](https://review.byted.org/#/q/cedda88))
* **group setting:** 修改文案 ([a28f21a](https://review.byted.org/#/q/a28f21a))
* **group_setting:** “Disband Grou” -> “Disband Group”,调整状态栏颜色 ([c294fa8](https://review.byted.org/#/q/c294fa8))
* **groupSetting:** 添加解散群组Alert，处理：数据源变化未ReloadTable 可能导致crash的问题 ([185b692](https://review.byted.org/#/q/185b692))
* **groupSettings:** 走查 BUG fix,文案错误，Title行高 ([7d0e6b4](https://review.byted.org/#/q/7d0e6b4))
* **I18n.swift:** 修复I18n冲突 ([2ea0ec3](https://review.byted.org/#/q/2ea0ec3))
* **message:** iOS 10.2以下消息气泡展示不全的问题 ([b85e54a](https://review.byted.org/#/q/b85e54a)), closes [#1729](https://jira.bytedance.com/browse/LKI-1729)
* **message:** url为空导致错乱的问题,可能导致不明中缓存的问题 ([d2e17e3](https://review.byted.org/#/q/d2e17e3)), closes [#1874](https://jira.bytedance.com/browse/LKI-1874)
* **message:** 修复取消合并转发时 checkbox 不去掉的问题. ([2dffc9d](https://review.byted.org/#/q/2dffc9d)), closes [#1305](https://jira.bytedance.com/browse/LKI-1305)
* **message:** 修复搜狗换行在其他端无法显示 ([df5772b](https://review.byted.org/#/q/df5772b)), closes [#1763](https://jira.bytedance.com/browse/LKI-1763)
* **message:** 修复获取摘要crash，存在type ok，但是content解析不出来的情况 ([3be622d](https://review.byted.org/#/q/3be622d)), closes [#1877](https://jira.bytedance.com/browse/LKI-1877)
* **message:** 去掉合并转发内部控制逻辑, 由调用组件决定是否显示. ([ab32836](https://review.byted.org/#/q/ab32836)), closes [#1305](https://jira.bytedance.com/browse/LKI-1305)
* **message:** 增加打点和修复部分打点丢失 ([117511e](https://review.byted.org/#/q/117511e)), closes [#1838](https://jira.bytedance.com/browse/LKI-1838) [#1871](https://jira.bytedance.com/browse/LKI-1871) [#1872](https://jira.bytedance.com/browse/LKI-1872)
* **message:** 断网发消息，失败的消息没有显示头像 ([f5266c4](https://review.byted.org/#/q/f5266c4)), closes [#1896](https://jira.bytedance.com/browse/LKI-1896)
* **message:** 时间显示修改. ([406c387](https://review.byted.org/#/q/406c387)), closes [#1801](https://jira.bytedance.com/browse/LKI-1801)
* **message:** 气泡走查相关问题处理 ([3046a8e](https://review.byted.org/#/q/3046a8e)), closes [#1873](https://jira.bytedance.com/browse/LKI-1873)
* **message:** 水印没有显示用户名 ([9f33d34](https://review.byted.org/#/q/9f33d34)), closes [#1899](https://jira.bytedance.com/browse/LKI-1899)
* **message:** 组织架构页面奔溃、修复个人资料页面更多push两次、单聊建群crash ([b31c942](https://review.byted.org/#/q/b31c942)), closes [#1890](https://jira.bytedance.com/browse/LKI-1890) [#1887](https://jira.bytedance.com/browse/LKI-1887)
* **message:** 部分长文本截断和 LKLabel 截断不同, 导致该显示"查看更多"时没有显示. ([fefb076](https://review.byted.org/#/q/fefb076)), closes [#1867](https://jira.bytedance.com/browse/LKI-1867)
* **urgency:** 加急消息 增加断网重连拉取逻辑 ([fab423b](https://review.byted.org/#/q/fab423b)), closes [#1856](https://jira.bytedance.com/browse/LKI-1856)
* 修复QRCodeVC扫码Push失败问题 ([22f53c0](https://review.byted.org/#/q/22f53c0))
* 日历bot提醒屏蔽reaction和menu ([3d35881](https://review.byted.org/#/q/3d35881))


### Features

* **calendar:** 日历1.2.13版本开发完成，申请并入主分支 ([43ab83e](https://review.byted.org/#/q/43ab83e))
* **Calendar:** 由于同时存在页面的横向和纵向滚动，在日历模块构造时存在默认的横向滚动调整，在当前mainloop中再出发内部的纵向滚动会失效，因此，做下一mainloop调度，后续将动 ([7faaa29](https://review.byted.org/#/q/7faaa29))
* **Calendar:** 解决Calendar滑动卡顿的问题 ([47d1a8e](https://review.byted.org/#/q/47d1a8e))
* **contact:** 个人名片上增加工号信息，放在邮箱后、城市前 ([0600b4e](https://review.byted.org/#/q/0600b4e)), closes [#1605](https://jira.bytedance.com/browse/LKI-1605)
* **email:** 优化邮件@与加急 ([d0cde84](https://review.byted.org/#/q/d0cde84)), closes [#1767](https://jira.bytedance.com/browse/LKI-1767)
* **LarkTracer:** 增加appFullVersion的header标记 ([c32ff2a](https://review.byted.org/#/q/c32ff2a))
* **message:** 云盘0.2需求-云盘文件分享链接跳进 OAuth 认证页面 ([89b39bc](https://review.byted.org/#/q/89b39bc)), closes [#1855](https://jira.bytedance.com/browse/LKI-1855)
* **message:** 优化处理合并转发的消息数目, 提升性能, 能展示表情. ([45ae98a](https://review.byted.org/#/q/45ae98a)), closes [#1305](https://jira.bytedance.com/browse/LKI-1305)
* **message:** 修复合并转发的展示问题. ([fa7abb5](https://review.byted.org/#/q/fa7abb5)), closes [#1305](https://jira.bytedance.com/browse/LKI-1305)
* **message:** 增加合并转发类消息 ([7640165](https://review.byted.org/#/q/7640165)), closes [#1305](https://jira.bytedance.com/browse/LKI-1305)
* 日历选择联系人界面部分国际化 ([5be5b62](https://review.byted.org/#/q/5be5b62))
* **tracker:** 调整打点启动时机，由登录后提前到app启动时就调用TTTracker ([49f7e79](https://review.byted.org/#/q/49f7e79))



<a name="1.4.1"></a>
## 1.4.1 (2018-05-14)


### Bug Fixes

* **contact:** toolbar布局不对，同步消息dismiss时crash ([bde3daf](https://review.byted.org/#/q/bde3daf)), closes [#1845](https://jira.bytedance.com/browse/LKI-1845) [#1848](https://jira.bytedance.com/browse/LKI-1848)
* **email:** 修复H5页面取到图片仍是旧素材 ([11cd4bf](https://review.byted.org/#/q/11cd4bf)), closes [#1854](https://jira.bytedance.com/browse/LKI-1854)
* **message:** 解决chat页面两处crash(具体见jira issue) ([ee0e7c3](https://review.byted.org/#/q/ee0e7c3)), closes [#1847](https://jira.bytedance.com/browse/LKI-1847)


### Features

* **chat:** at 人权限设置 ([ef99681](https://review.byted.org/#/q/ef99681)), closes [#1795](https://jira.bytedance.com/browse/LKI-1795)
* **chat:** push hide channel ([81a8e09](https://review.byted.org/#/q/81a8e09)), closes [#1799](https://jira.bytedance.com/browse/LKI-1799)



<a name="1.4.0"></a>
# 1.4.0 (2018-05-10)


### Bug Fixes

* **chat:** 修复menu vc 旋转问题 ([1c6e0c8](https://review.byted.org/#/q/1c6e0c8)), closes [#1826](https://jira.bytedance.com/browse/LKI-1826)
* **chat:** 修复富文本编辑页面复制不触发发送按钮刷新 ([2fd7727](https://review.byted.org/#/q/2fd7727)), closes [#1834](https://jira.bytedance.com/browse/LKI-1834)
* **message:** 解决reation在加急后被冲掉的问题 ([3590d25](https://review.byted.org/#/q/3590d25)), closes [#1829](https://jira.bytedance.com/browse/LKI-1829)
* **message:** 解决单聊建群少一人的问题 ([9fd6dc0](https://review.byted.org/#/q/9fd6dc0)), closes [#1807](https://jira.bytedance.com/browse/LKI-1807)


### Features

* **larkDev:** 解决larkDev编译后的包，启动闪退问题 ([ee5478a](https://review.byted.org/#/q/ee5478a))



<a name="1.4.0-beta3"></a>
# 1.4.0-beta3 (2018-05-09)


### Bug Fixes

* **Calendar:** 日历从详情页返回视图页视图页标题删一下的修复 ([b963a3c](https://review.byted.org/#/q/b963a3c))
* **message:** 优化部分小细节. ([14dbcbe](https://review.byted.org/#/q/14dbcbe)), closes [#1822](https://jira.bytedance.com/browse/LKI-1822) [#1823](https://jira.bytedance.com/browse/LKI-1823)
* **message:** 解决Lark与其他软件声音播放冲突的问题 ([e7d33e8](https://review.byted.org/#/q/e7d33e8)), closes [#1755](https://jira.bytedance.com/browse/LKI-1755)



<a name="1.4.0-beta2"></a>
# 1.4.0-beta2 (2018-05-07)


### Bug Fixes

* **email:** 优化邮件加急选人 ([c275323](https://review.byted.org/#/q/c275323)), closes [#1809](https://jira.bytedance.com/browse/LKI-1809)
* **email:** 修复 feed email cell ([6d931a2](https://review.byted.org/#/q/6d931a2)), closes [#1766](https://jira.bytedance.com/browse/LKI-1766)
* **message:** 1.邮件本地推送文案调整 2.通知设置文案折行处理 ([0df4708](https://review.byted.org/#/q/0df4708)), closes [#1808](https://jira.bytedance.com/browse/LKI-1808)
* **message:** 加急确认名字随语言环境，修复删除文案高亮不对 ([fe1af10](https://review.byted.org/#/q/fe1af10)), closes [#1804](https://jira.bytedance.com/browse/LKI-1804)
* **message:** 单聊内建群，拉了第三人后，选了同步消息，群名称仅仅是两个成员的姓名组合，应该是三个成员的组合 ([0dfc82d](https://review.byted.org/#/q/0dfc82d)), closes [#1807](https://jira.bytedance.com/browse/LKI-1807)
* **message:** 点击拨打电话系统消息的@进入名片 ([f315b48](https://review.byted.org/#/q/f315b48)), closes [#1817](https://jira.bytedance.com/browse/LKI-1817)
* **message:** 语言设置里多一项“系统语言” ([9b2c845](https://review.byted.org/#/q/9b2c845)), closes [#1515](https://jira.bytedance.com/browse/LKI-1515)
* **message:** 退群不在提示“你已退出群聊” ([a64be7f](https://review.byted.org/#/q/a64be7f)), closes [#1646](https://jira.bytedance.com/browse/LKI-1646)


### Features

* **Calendar:** 1.2.10上车 ([2edcc97](https://review.byted.org/#/q/2edcc97))



<a name="1.4.0-beta1"></a>
# 1.4.0-beta1 (2018-05-06)


### Bug Fixes

* **Calendar:** 全局提醒显示逻辑优化 ([e4603af](https://review.byted.org/#/q/e4603af))
* **Calendar:** 日历全局提醒去重 ([fdc467f](https://review.byted.org/#/q/fdc467f))
* **chat:** fix menu 消失键盘遮挡 table ([8a3be93](https://review.byted.org/#/q/8a3be93)), closes [#1793](https://jira.bytedance.com/browse/LKI-1793)
* **chat:** 修复thread页面刷新次数和图片回调线程问题 ([abc174e](https://review.byted.org/#/q/abc174e)), closes [#1789](https://jira.bytedance.com/browse/LKI-1789)
* **contact:** 个人名片页相同城市不显示城市. ([5b3ecd1](https://review.byted.org/#/q/5b3ecd1)), closes [#1762](https://jira.bytedance.com/browse/LKI-1762)
* **email:** feed system event 信息不全 ([de3b71e](https://review.byted.org/#/q/de3b71e)), closes [#1791](https://jira.bytedance.com/browse/LKI-1791)
* **login:** fix issue: Can't show login input view on iOS 9 sometimes. ([8dd114b](https://review.byted.org/#/q/8dd114b)), closes [#1714](https://jira.bytedance.com/browse/LKI-1714)
* **login:** fix issue: use a safe way to logout session. Even if EELogin module do not contains the ([c08fffd](https://review.byted.org/#/q/c08fffd)), closes [#1714](https://jira.bytedance.com/browse/LKI-1714)
* **message:** 修复详情页图标显示不对 ([72dae82](https://review.byted.org/#/q/72dae82)), closes [#1675](https://jira.bytedance.com/browse/LKI-1675)
* **message:** 富文本编辑页面拖动引起失焦BUG ([49bbd69](https://review.byted.org/#/q/49bbd69)), closes [#1771](https://jira.bytedance.com/browse/LKI-1771)
* **search:** 搜索中点击 sheet 会报异常 ([2150845](https://review.byted.org/#/q/2150845)), closes [#1778](https://jira.bytedance.com/browse/LKI-1778)


### Features

* **calendar:** 增加前置检测条件，仅仅当出现日历卡片消息时，才调用可能出发闪退的接口，降低闪退的概率，暂时没找到root cause，继续调查 ([92ddd13](https://review.byted.org/#/q/92ddd13))
* **setting:** 上传语言设置, 统一语言存储的key ([784e2ad](https://review.byted.org/#/q/784e2ad)), closes [#1714](https://jira.bytedance.com/browse/LKI-1714)
* **setting:** 群描述样式修改 ([9dbce18](https://review.byted.org/#/q/9dbce18)), closes [#1678](https://jira.bytedance.com/browse/LKI-1678)
* **tracer:** 增加recordEventWithKeys接口，对应TTTracker的ttTraceWithCustomKeys ([e9d3092](https://review.byted.org/#/q/e9d3092))
* **tracer:** 增加recordEventWithKeys接口，对应TTTracker的ttTraceWithCustomKeys ([259468a](https://review.byted.org/#/q/259468a))



<a name="1.3.7"></a>
## 1.3.7 (2018-04-27)


### Bug Fixes

* **calendarContent:** 修复解析服务器数据时未能解析重复规则数据的问题 ([35b3a01](https://review.byted.org/#/q/35b3a01))
* **component:** 修复插入图片引起的键盘错误 ([e8fe402](https://review.byted.org/#/q/e8fe402)), closes [#1742](https://jira.bytedance.com/browse/LKI-1742)
* **component:** 修复由于监听顺序调整造成的无法拉取电话的BUG ([4f42011](https://review.byted.org/#/q/4f42011)), closes [#1740](https://jira.bytedance.com/browse/LKI-1740)
* **email:** 修复详情页面无法显示图片的BUG ([9c6a868](https://review.byted.org/#/q/9c6a868)), closes [#1744](https://jira.bytedance.com/browse/LKI-1744)
* **login:** clean logout before login. ([ee1150a](https://review.byted.org/#/q/ee1150a)), closes [#1714](https://jira.bytedance.com/browse/LKI-1714)
* **login:** Make sure device id is ready before do login. ([9b1a38e](https://review.byted.org/#/q/9b1a38e)), closes [#1713](https://jira.bytedance.com/browse/LKI-1713)
* **login:** 在真正登出时，同步调用rust sdk的logout方法，清理rust sdk内部数据。 ([55780c4](https://review.byted.org/#/q/55780c4)), closes [#1711](https://jira.bytedance.com/browse/LKI-1711)
* update Calendar version ([36dd564](https://review.byted.org/#/q/36dd564))
* **login:** 设备被踢出后，退回登陆界面 ([5da64fb](https://review.byted.org/#/q/5da64fb)), closes [#1730](https://jira.bytedance.com/browse/LKI-1730)
* **login:** 设备被踢出后，退回登陆界面 ([dc102a2](https://review.byted.org/#/q/dc102a2)), closes [#1730](https://jira.bytedance.com/browse/LKI-1730)
* 修复第一次进入thread无法scroll message的问题 ([3d804e3](https://review.byted.org/#/q/3d804e3))
* **message:** iOS 10.2以下消息气泡展示不全的问题 ([d36537e](https://review.byted.org/#/q/d36537e)), closes [#1729](https://jira.bytedance.com/browse/LKI-1729)
* **message:** 修复详情页发消息一直loading问题 ([5ef986b](https://review.byted.org/#/q/5ef986b)), closes [#1756](https://jira.bytedance.com/browse/LKI-1756)
* **message:** 修复部分展示的小问题. ([53ef08b](https://review.byted.org/#/q/53ef08b)), closes [#1745](https://jira.bytedance.com/browse/LKI-1745)
* **message:** 修正首页直接点击tableheader进入通知设置页时，状态显示不对的问题 ([968eff8](https://review.byted.org/#/q/968eff8)), closes [#1743](https://jira.bytedance.com/browse/LKI-1743)
* **message:** 发送gif图片时被错误的转换成为第一帧发送 ([d3b0002](https://review.byted.org/#/q/d3b0002)), closes [#1739](https://jira.bytedance.com/browse/LKI-1739)


### Features

* **calendar:** 在日程发生后依然会出现全局提醒 ([9874bb2](https://review.byted.org/#/q/9874bb2))
* **calendar:** 调整statusBar颜色为黑色 ([145a3af](https://review.byted.org/#/q/145a3af))
* **Calendar:** 日历功能去除feature gating，默认对所有人开放 ([de468b2](https://review.byted.org/#/q/de468b2))
* **chat:** 「多租户」，非字节跳动租户，关于Lark，不显示效率工程logo ([806b614](https://review.byted.org/#/q/806b614)), closes [#1726](https://jira.bytedance.com/browse/LKI-1726)
* **chat:** 更新已读、打电话、多设备、删除/设置文案 ([cdd6128](https://review.byted.org/#/q/cdd6128)), closes [#1528](https://jira.bytedance.com/browse/LKI-1528)
* **contact:** 多租户权限控制. ([bf53f43](https://review.byted.org/#/q/bf53f43)), closes [#1699](https://jira.bytedance.com/browse/LKI-1699)
* **general:** 修改内部设置菜单，仅仅在头条用户显示 ([65c8b19](https://review.byted.org/#/q/65c8b19))
* **general:** 切换使用pushSDK上报apns token信息 ([f2f0d6e](https://review.byted.org/#/q/f2f0d6e))
* **general:** 删除日志输出，隐藏多租户加密后的串 ([0e871b2](https://review.byted.org/#/q/0e871b2))
* **general:** 去掉GA打点库，仅仅使用头条TEE作为打点服务 ([09d3c2c](https://review.byted.org/#/q/09d3c2c))
* **login:** Use EELogin Module to deal with Login View. ([15d9f9c](https://review.byted.org/#/q/15d9f9c)), closes [#1714](https://jira.bytedance.com/browse/LKI-1714)
* **login:** Use EELogin Module to deal with Login View. ([3b1aca8](https://review.byted.org/#/q/3b1aca8)), closes [#1714](https://jira.bytedance.com/browse/LKI-1714)
* **login:** 为account数据结构增加租户信息，便于查询。 ([56d42dd](https://review.byted.org/#/q/56d42dd)), closes [#1723](https://jira.bytedance.com/browse/LKI-1723)
* **message:** 多租户上传日志方法——连点5次「关于Lark」的logo区域，触发调试界面，点击上传日志，打包日志，发送日志给自己。 ([297a819](https://review.byted.org/#/q/297a819)), closes [#1727](https://jira.bytedance.com/browse/LKI-1727)
* **resources:** 修改日程提醒音 ([7b5e405](https://review.byted.org/#/q/7b5e405))
* **setting:** 完善工作状态 ([733d420](https://review.byted.org/#/q/733d420)), closes [#493](https://jira.bytedance.com/browse/LKI-493)
* **setting:** 显示工作状态 ([f7b8361](https://review.byted.org/#/q/f7b8361)), closes [#493](https://jira.bytedance.com/browse/LKI-493)
* **setting:** 适配多租户 ([ae28dcc](https://review.byted.org/#/q/ae28dcc)), closes [#1693](https://jira.bytedance.com/browse/LKI-1693)
* **tracer:** 实现多租户id统计，打包时删除x86指令集确保可以提交到appleStore ([8af2f79](https://review.byted.org/#/q/8af2f79))
* **tracker:** 更新tracker库为动态库 ([b614eed](https://review.byted.org/#/q/b614eed))
* **tracker:** 更新tracker库为动态库 ([41bf06e](https://review.byted.org/#/q/41bf06e))
* **tracker:** 更新打点库 ([8717223](https://review.byted.org/#/q/8717223))
* **web:** 优化：头条圈没加载完成时，点击帖子中的链接都没反应，将bridge提前注入 ([86e7d64](https://review.byted.org/#/q/86e7d64)), closes [#1716](https://jira.bytedance.com/browse/LKI-1716)



<a name="1.3.4"></a>
## 1.3.4 (2018-04-11)


### Bug Fixes

* **calendar:** 修复日历小助手提醒不够稳定的问题 ([6e18461](https://review.byted.org/#/q/6e18461))
* **component:** 修复导航拖动返回BUG ([177ef7f](https://review.byted.org/#/q/177ef7f)), closes [#1721](https://jira.bytedance.com/browse/LKI-1721)
* **email:** 修复删除未上传成功的邮件附件 ([3f07db7](https://review.byted.org/#/q/3f07db7)), closes [#1710](https://jira.bytedance.com/browse/LKI-1710)


### Features

* **chat:** 群成员上限2000 ([6ea230e](https://review.byted.org/#/q/6ea230e)), closes [#1707](https://jira.bytedance.com/browse/LKI-1707)
* **email:** 邮件附件暂时取消保存云盘功能 ([f822375](https://review.byted.org/#/q/f822375)), closes [#1708](https://jira.bytedance.com/browse/LKI-1708)
* **login:** apply EELogin framework log system to SLogger ([1bbdf85](https://review.byted.org/#/q/1bbdf85)), closes [#1713](https://jira.bytedance.com/browse/LKI-1713)
* **setting:** 工作状态 ([9b8102a](https://review.byted.org/#/q/9b8102a)), closes [#493](https://jira.bytedance.com/browse/LKI-493)



<a name="1.3.3"></a>
## 1.3.3 (2018-04-03)


### Bug Fixes

* **chat:** 应用内分享路由参数做url编码 ([b463408](https://review.byted.org/#/q/b463408)), closes [#1691](https://jira.bytedance.com/browse/LKI-1691)
* **component:** 修改编译问题 ([e21ddd2](https://review.byted.org/#/q/e21ddd2)), closes [#1701](https://jira.bytedance.com/browse/LKI-1701)
* **component:** 修改进入App Center页面，就会弹出定位提示的bug ([4cf6596](https://review.byted.org/#/q/4cf6596)), closes [#1701](https://jira.bytedance.com/browse/LKI-1701)
* **message:** 修复at绿点处理一乱码的问题 ([831dfae](https://review.byted.org/#/q/831dfae)), closes [#1676](https://jira.bytedance.com/browse/LKI-1676)
* **message:** 修复at绿点处理一乱码的问题 ([4aec824](https://review.byted.org/#/q/4aec824)), closes [#1676](https://jira.bytedance.com/browse/LKI-1676)
* **message:** 修复发送附件，读取手机视频读取不全的问题 ([46dfdd7](https://review.byted.org/#/q/46dfdd7)), closes [#1688](https://jira.bytedance.com/browse/LKI-1688)
* **web:** 头条圈图片上传失败后，返回失效，生成1.3.3changelog ([2c0b5de](https://review.byted.org/#/q/2c0b5de)), closes [#1690](https://jira.bytedance.com/browse/LKI-1690)


### Features

* **calendar:** 修改featuregating确认窗口的样式，以及文案 ([088c560](https://review.byted.org/#/q/088c560))
* **calendar:** 提交featureGating的framework集成 ([ab87428](https://review.byted.org/#/q/ab87428))
* **Calendar:** 日历全局提醒显示逻辑改变 ([41a073d](https://review.byted.org/#/q/41a073d))
* **component:** 优化导航栏滑动返回 ([b6f388d](https://review.byted.org/#/q/b6f388d)), closes [#1679](https://jira.bytedance.com/browse/LKI-1679)
* **contact:** 添加工作状态API ([a4b66e0](https://review.byted.org/#/q/a4b66e0)), closes [#1680](https://jira.bytedance.com/browse/LKI-1680)
* **feed:** finish doc feed search & refactor some dirty code ([03c3556](https://review.byted.org/#/q/03c3556)), closes [#934](https://jira.bytedance.com/browse/LKI-934)



<a name="1.3.2"></a>
## 1.3.2 (2018-03-25)


### Bug Fixes

* **chat:** 群名称上限提高至80个字符 ([4db3549](https://review.byted.org/#/q/4db3549)), closes [#1028](https://jira.bytedance.com/browse/LKI-1028)
* **docs:** 修正 doc VC 拖动返回手势 enable ([2f54d8e](https://review.byted.org/#/q/2f54d8e)), closes [#1677](https://jira.bytedance.com/browse/LKI-1677)
* **email:** 修复了超长图片显示模糊的问题 ([edd3b1a](https://review.byted.org/#/q/edd3b1a)), closes [#1662](https://jira.bytedance.com/browse/LKI-1662)
* **email:** 修正邮件联系人显示不全的问题 ([be1c6f4](https://review.byted.org/#/q/be1c6f4)), closes [#1670](https://jira.bytedance.com/browse/LKI-1670)
* **message:** 发送附件的时候，选择系统图库中的视频，第一遍发送不出去 ([5d27686](https://review.byted.org/#/q/5d27686)), closes [#1665](https://jira.bytedance.com/browse/LKI-1665)
* **message:** 支持集成的第三方应用lark内分享行为 ([c502fa6](https://review.byted.org/#/q/c502fa6)), closes [#1664](https://jira.bytedance.com/browse/LKI-1664)
* **message:** 更新大点库验证发布版本，解决uid加密不生效问题 ([7bcd5f9](https://review.byted.org/#/q/7bcd5f9))


### Features

* **calendar:** 实现大点组件的calendar适配 ([2ccdbb5](https://review.byted.org/#/q/2ccdbb5))
* **calendar:** 更新大点库，验证uid加密 ([bf336a7](https://review.byted.org/#/q/bf336a7))
* **calendar:** 更新打点库，验证UID加密 ([0550af7](https://review.byted.org/#/q/0550af7))
* **calendar:** 解决跨天后，日程需要重排，将当天移动到第0页的第一列 ([464d088](https://review.byted.org/#/q/464d088))
* **Calendar:** 增添点击底部状态栏图标即使在当前页也会显示红线的需求 ([e03a1d8](https://review.byted.org/#/q/e03a1d8))
* **Calendar:** 搜索参与人时要求可以多选 ([4454aba](https://review.byted.org/#/q/4454aba))
* **component:** 为开发平台的H5提供定位功能 ([f857975](https://review.byted.org/#/q/f857975)), closes [#1666](https://jira.bytedance.com/browse/LKI-1666)
* **component:** 优化 UIWebView 拖动返回 ([455d6df](https://review.byted.org/#/q/455d6df)), closes [#1667](https://jira.bytedance.com/browse/LKI-1667)
* **component:** 新UI, chat页面NaviBar改造 ([a3ee723](https://review.byted.org/#/q/a3ee723)), closes [#1671](https://jira.bytedance.com/browse/LKI-1671)
* **component:** 新UI, titleBar改造。加入滑动改变naviBar透明度的效果 ([322d9d2](https://review.byted.org/#/q/322d9d2)), closes [#1671](https://jira.bytedance.com/browse/LKI-1671)
* **component:** 新UI, titleBar改造。现在接入feedViewContorller和AppCenterViewController两个界面 ([7affb47](https://review.byted.org/#/q/7affb47)), closes [#1671](https://jira.bytedance.com/browse/LKI-1671)
* **component:** 更新 VoIP 到 0.2.0 ([d331e82](https://review.byted.org/#/q/d331e82)), closes [#1672](https://jira.bytedance.com/browse/LKI-1672)
* **dayView:** 更新calenar库的repo，指向1.1.0 ([a82c1af](https://review.byted.org/#/q/a82c1af))
* **docs:** 单聊建群同步消息，支持根据url和建群人的权限关系，判断是否允许授权。 ([23a455c](https://review.byted.org/#/q/23a455c)), closes [#1663](https://jira.bytedance.com/browse/LKI-1663)
* **feed:** integrate doc in feed II ([3bf6a96](https://review.byted.org/#/q/3bf6a96)), closes [#934](https://jira.bytedance.com/browse/LKI-934)


### Performance Improvements

* **calendar:** 优化-在今天的其他时间点击日历icon，回到当前时间，期望有动画 ([79ee025](https://review.byted.org/#/q/79ee025))



<a name="1.3.1"></a>
## 1.3.1 (2018-03-16)


### Bug Fixes

* **contact:** 拨打电话提示弹框文案修改 ([123c9fc](https://review.byted.org/#/q/123c9fc)), closes [#1648](https://jira.bytedance.com/browse/LKI-1648)
* **docs:** 修复问题：https://docs.bytedance.net/doc/IXxCKrfhJg4LysVv7wPN8c ([fa5f388](https://review.byted.org/#/q/fa5f388)), closes [#1657](https://jira.bytedance.com/browse/LKI-1657)
* **docs:** 单聊建群授权没生效、修改权限完成弹toast ([31c53d6](https://review.byted.org/#/q/31c53d6)), closes [#1651](https://jira.bytedance.com/browse/LKI-1651)
* **email:** 修复部分 Email BUG ([4d85ebd](https://review.byted.org/#/q/4d85ebd)), closes [#1653](https://jira.bytedance.com/browse/LKI-1653)
* **message:** 修复at所有人时，显示的选中内容带有人数的问题 ([d9f559f](https://review.byted.org/#/q/d9f559f)), closes [#1659](https://jira.bytedance.com/browse/LKI-1659)
* **message:** 创建群聊时，弹窗显示位置不对 ([2ce6e14](https://review.byted.org/#/q/2ce6e14)), closes [#1660](https://jira.bytedance.com/browse/LKI-1660)
* **search:** 修正searchfeedback传参错误(单聊传对应的user) ([040167e](https://review.byted.org/#/q/040167e)), closes [#1649](https://jira.bytedance.com/browse/LKI-1649)


### Features

* **calendar:** rebase dev ([b932fc6](https://review.byted.org/#/q/b932fc6))
* **calendar:** 解决无法打开日程参与者选人控件问题 ([7a12989](https://review.byted.org/#/q/7a12989))
* **contact:** 对接新的组织架构接口 ([3659e5e](https://review.byted.org/#/q/3659e5e)), closes [#1625](https://jira.bytedance.com/browse/LKI-1625)



<a name="1.3.0"></a>
# 1.3.0 (2018-03-12)


### Bug Fixes

* **contact:** 优化拨打电话权限控制流程, 补充文案和资源文件国际化. ([19571c7](https://review.byted.org/#/q/19571c7)), closes [#1619](https://jira.bytedance.com/browse/LKI-1619)
* **docs:** 关闭docs预览，增加几个文案国际化 ([24bc769](https://review.byted.org/#/q/24bc769)), closes [#1643](https://jira.bytedance.com/browse/LKI-1643) [#1644](https://jira.bytedance.com/browse/LKI-1644) [#1645](https://jira.bytedance.com/browse/LKI-1645)
* **login:** Create new cookie and set to CookieStorage when reach to expires date ([02862df](https://review.byted.org/#/q/02862df)), closes [#1639](https://jira.bytedance.com/browse/LKI-1639)
* **login:** 修复更新Cookie Expires Date未判断Cookie Name的问题 ([20f9803](https://review.byted.org/#/q/20f9803)), closes [#1639](https://jira.bytedance.com/browse/LKI-1639)
* **message:** 单聊设置、单聊建群翻译 ([c201100](https://review.byted.org/#/q/c201100)), closes [#1614](https://jira.bytedance.com/browse/LKI-1614)



<a name="1.3.0-beta3"></a>
# 1.3.0-beta3 (2018-03-09)


### Bug Fixes

* **calendar:** 加入丢失的weak ([2f3554d](https://review.byted.org/#/q/2f3554d)), closes [#1596](https://jira.bytedance.com/browse/LKI-1596)
* **docs:** 权限设置后，cell上没有更新，摘要乱码先不显示 ([c7bda6a](https://review.byted.org/#/q/c7bda6a)), closes [#1635](https://jira.bytedance.com/browse/LKI-1635)
* **email:** CustomizableActionSheet的使用方式，默认展示在keywindow上 ([e8e8e73](https://review.byted.org/#/q/e8e8e73)), closes [#1641](https://jira.bytedance.com/browse/LKI-1641)
* **email:** Email详情页点击@群组 的时候不应该跳转到个人资料页 ([76231c7](https://review.byted.org/#/q/76231c7)), closes [#1607](https://jira.bytedance.com/browse/LKI-1607)
* **email:** 邮件详情页点击链接会push新VC 但是原页面也会跳转到link页面 ([00c5713](https://review.byted.org/#/q/00c5713)), closes [#1629](https://jira.bytedance.com/browse/LKI-1629)
* **email:** 邮件详情页相关问题修复 ([83b2f0c](https://review.byted.org/#/q/83b2f0c)), closes [#1618](https://jira.bytedance.com/browse/LKI-1618)
* 打测试环境包 ([d5dae8c](https://review.byted.org/#/q/d5dae8c))
* **Framework:** 添加merge过程中丢失的文件 ([d480422](https://review.byted.org/#/q/d480422))
* **LarkCalendarHomeViewController::** 保证红线出现的时间正确 ([1cc220c](https://review.byted.org/#/q/1cc220c))
* **login:** 修复CookieStorage中的Cookie过期问题 ([91a4ab6](https://review.byted.org/#/q/91a4ab6)), closes [#1639](https://jira.bytedance.com/browse/LKI-1639)
* **message:** ReactionTagVIew展示不全 ([efd0979](https://review.byted.org/#/q/efd0979)), closes [#1642](https://jira.bytedance.com/browse/LKI-1642)
* **message:** 修复@某人时 url 渲染少一位的问题; url渲染不由系统判定. ([cee8474](https://review.byted.org/#/q/cee8474)), closes [#1626](https://jira.bytedance.com/browse/LKI-1626)
* **message:** 修复回复指定消息，进入其他页面，草稿会丢失的问题 ([4137e14](https://review.byted.org/#/q/4137e14)), closes [#1637](https://jira.bytedance.com/browse/LKI-1637)
* **message:** 修改发送附件成功埋点不正确的问题 ([6e276c4](https://review.byted.org/#/q/6e276c4)), closes [#1602](https://jira.bytedance.com/browse/LKI-1602)
* **message:** 修改部分文案, 群公告改成发送帖子消息 ([e25257b](https://review.byted.org/#/q/e25257b)), closes [#1614](https://jira.bytedance.com/browse/LKI-1614)
* **message:** 发送失败的消息支持复制 ([5ecb6b2](https://review.byted.org/#/q/5ecb6b2)), closes [#1633](https://jira.bytedance.com/browse/LKI-1633)
* **message:** 未知消息气泡显示"收到一条未知类型的消息，请更新到最新版本" ([82fcf77](https://review.byted.org/#/q/82fcf77)), closes [#1640](https://jira.bytedance.com/browse/LKI-1640)
* 4号测试时，日历tab上的icon还是显示的2号，没有及时更新 ([791340b](https://review.byted.org/#/q/791340b))
* fix ([dc9b925](https://review.byted.org/#/q/dc9b925))
* try ([0ca2b5b](https://review.byted.org/#/q/0ca2b5b))
* **message:** 解决遇到一个xlsx文件打不开 （彭烨的Lark客服群） ([c895cdd](https://review.byted.org/#/q/c895cdd)), closes [#1636](https://jira.bytedance.com/browse/LKI-1636)
* **tracker:** 实现UID加密逻辑 ([da9d969](https://review.byted.org/#/q/da9d969))
* whats new show all changes ([48e89db](https://review.byted.org/#/q/48e89db))
* 修复lark图标消失的问题 ([5ef2c94](https://review.byted.org/#/q/5ef2c94))
* 修复了部分情况下卡片消息无法显示与会者的问题 ([d90af5a](https://review.byted.org/#/q/d90af5a))
* 修复图标问题 ([129d92a](https://review.byted.org/#/q/129d92a))
* 修复打包问题 ([313084a](https://review.byted.org/#/q/313084a))
* 恢复测试环境 ([ecc2778](https://review.byted.org/#/q/ecc2778))
* 无法打包问题 ([3b6d590](https://review.byted.org/#/q/3b6d590))
* 更改到正式环境 ([e40928e](https://review.byted.org/#/q/e40928e))


### Features

* **API:** 解析日历的模板消息并完成model ([2619615](https://review.byted.org/#/q/2619615))
* **appDelegate:** 为本地推送提供接口 ([289eab9](https://review.byted.org/#/q/289eab9))
* **calendar:** 加入日历全局提醒 ([23ec60b](https://review.byted.org/#/q/23ec60b)), closes [#1596](https://jira.bytedance.com/browse/LKI-1596)
* **chat:** 修改群公告去掉[@all](http://git.byted.org:29418/all) ([bf10e18](https://review.byted.org/#/q/bf10e18)), closes [#1612](https://jira.bytedance.com/browse/LKI-1612)
* **chat:** 群公告保存时发送的消息不再自动拼[@all](http://git.byted.org:29418/all) ([1fa1592](https://review.byted.org/#/q/1fa1592)), closes [#1612](https://jira.bytedance.com/browse/LKI-1612)
* **contact:** 拨打电话权限控制, 不常联系人增加加急消息提示 ([ee88cb3](https://review.byted.org/#/q/ee88cb3)), closes [#1619](https://jira.bytedance.com/browse/LKI-1619)
* **docs:** Docs权限管理SwipViewController done ([2f3ecb8](https://review.byted.org/#/q/2f3ecb8)), closes [#1598](https://jira.bytedance.com/browse/LKI-1598)
* **docs:** doc权限预览cell和权限设置 ([f2e140f](https://review.byted.org/#/q/f2e140f)), closes [#1604](https://jira.bytedance.com/browse/LKI-1604)
* **docs:** 单聊建群时文档消息时增加授权机制. ([deb0f3c](https://review.byted.org/#/q/deb0f3c)), closes [#1611](https://jira.bytedance.com/browse/LKI-1611)
* 修复没有图标的问题 ([5a9ae91](https://review.byted.org/#/q/5a9ae91))
* **docs:** 增加docs打点，修复上传图片失败问题 ([f2efc5e](https://review.byted.org/#/q/f2efc5e)), closes [#1631](https://jira.bytedance.com/browse/LKI-1631)
* **docs:** 文档卡片相关接口 ([197300b](https://review.byted.org/#/q/197300b)), closes [#1608](https://jira.bytedance.com/browse/LKI-1608)
* **email:** 邮件sendMailPanel回调 && maxPosition实现 ([e4ec909](https://review.byted.org/#/q/e4ec909)), closes [#1621](https://jira.bytedance.com/browse/LKI-1621)
* **email:** 邮件加急功能，查看加急部分 ([31d354b](https://review.byted.org/#/q/31d354b)), closes [#1594](https://jira.bytedance.com/browse/LKI-1594)
* **email:** 邮件埋点 ([8fa30ef](https://review.byted.org/#/q/8fa30ef)), closes [#1606](https://jira.bytedance.com/browse/LKI-1606)
* 彻底支持卡片消息接受拒绝待定 ([d2052c3](https://review.byted.org/#/q/d2052c3))
* **email:** 邮件搜索相关 ([0c95f4d](https://review.byted.org/#/q/0c95f4d)), closes [#1597](https://jira.bytedance.com/browse/LKI-1597)
* **feed:** integrate doc feed push ([567e90c](https://review.byted.org/#/q/567e90c)), closes [#934](https://jira.bytedance.com/browse/LKI-934)
* 更新.a库 ([c07f730](https://review.byted.org/#/q/c07f730))
* **feed:** integrate doc in feed ([0c5a244](https://review.byted.org/#/q/0c5a244)), closes [#934](https://jira.bytedance.com/browse/LKI-934)
* 切换到正式环境 ([fae10ff](https://review.byted.org/#/q/fae10ff))
* **LarkCalendarHomeViewController:** 添加点击日历tabbar10次后显示bundleVersion的功能 ([eba8ebe](https://review.byted.org/#/q/eba8ebe))
* **message:** 点击消息显示消息时间 ([5190df4](https://review.byted.org/#/q/5190df4)), closes [#1485](https://jira.bytedance.com/browse/LKI-1485)
* **message:** 获取电话接口增加字段 ([d409950](https://review.byted.org/#/q/d409950)), closes [#1619](https://jira.bytedance.com/browse/LKI-1619)
* 卡片消息中与会者 ([6f6b28a](https://review.byted.org/#/q/6f6b28a))
* 支持卡片消息· ([9a05c64](https://review.byted.org/#/q/9a05c64))
* 显示与会者 ([a8fd541](https://review.byted.org/#/q/a8fd541))
* 转换到正式环境 ([4b460b5](https://review.byted.org/#/q/4b460b5))



<a name="1.2.23"></a>
## 1.2.23 (2018-02-27)


### Bug Fixes

* **email:**  修改邮件header发现的bug ([1cf22cb](https://review.byted.org/#/q/1cf22cb)), closes [#1580](https://jira.bytedance.com/browse/LKI-1580)
* **email:** 邮件详情页无法显示草稿 ([5263962](https://review.byted.org/#/q/5263962)), closes [#1593](https://jira.bytedance.com/browse/LKI-1593)
* **message:** shit 表情渲染不正确 && 增加检测cookie同步是否正确的log ([1d28acc](https://review.byted.org/#/q/1d28acc)), closes [#1589](https://jira.bytedance.com/browse/LKI-1589)
* **message:** 选人页面按钮大小修改、帖子摘要显示标题 ([9691c70](https://review.byted.org/#/q/9691c70)), closes [#1595](https://jira.bytedance.com/browse/LKI-1595)
* **urgent:** 将加急电话标识存在keychain中，防止应用删除后，电话被反复添加 ([842dc85](https://review.byted.org/#/q/842dc85)), closes [#1584](https://jira.bytedance.com/browse/LKI-1584)


### Features

* **email:** 优化发邮件逻辑 ([02f2a1f](https://review.byted.org/#/q/02f2a1f)), closes [#1592](https://jira.bytedance.com/browse/LKI-1592)
* **email:** 邮件加急功能，修改邮件详情页，navigationBar右边...按钮出现的逻辑 ([905bb9a](https://review.byted.org/#/q/905bb9a)), closes [#1594](https://jira.bytedance.com/browse/LKI-1594)
* **email:** 邮件对接气泡 ([cc82400](https://review.byted.org/#/q/cc82400)), closes [#1438](https://jira.bytedance.com/browse/LKI-1438)
* 通知标题增加分支名 ([e65f50d](https://review.byted.org/#/q/e65f50d))



<a name="1.2.23-beta1"></a>
## 1.2.23-beta1 (2018-02-24)


### Bug Fixes

* **component:** 聊天标题和左上角消息数重叠 ([bf41fdb](https://review.byted.org/#/q/bf41fdb)), closes [#1582](https://jira.bytedance.com/browse/LKI-1582)
* **email:**  修改header 右边三角形按钮点击区域问题 ([82afa4e](https://review.byted.org/#/q/82afa4e)), closes [#1580](https://jira.bytedance.com/browse/LKI-1580)
* **email:** 1. “修改邮件主题，管理参与者”浮层位置不对 ([4d0e80f](https://review.byted.org/#/q/4d0e80f)), closes [#1580](https://jira.bytedance.com/browse/LKI-1580)
* **email:** EmailParseHelper bug修复 ([0518b1a](https://review.byted.org/#/q/0518b1a)), closes [#1552](https://jira.bytedance.com/browse/LKI-1552)
* **email:** Email正常显示 ([ef798d2](https://review.byted.org/#/q/ef798d2)), closes [#1550](https://jira.bytedance.com/browse/LKI-1550)
* **email:** 修复 feed list email 没有更新 last message BUG ([31bcc2d](https://review.byted.org/#/q/31bcc2d)), closes [#1586](https://jira.bytedance.com/browse/LKI-1586)
* **email:** 修复邮件上传图片找不到文件错误 ([b01505b](https://review.byted.org/#/q/b01505b)), closes [#1572](https://jira.bytedance.com/browse/LKI-1572)
* **email:** 修正 richtext 转化 BUG ([bfbb86e](https://review.byted.org/#/q/bfbb86e)), closes [#1575](https://jira.bytedance.com/browse/LKI-1575)
* **email:** 帖子和邮件预览图片按钮文案修改：发送->确定 ([4a75088](https://review.byted.org/#/q/4a75088)), closes [#1590](https://jira.bytedance.com/browse/LKI-1590)
* **email:** 接收新消息未根据根消息过滤，text暂不添加wrapper标签 ([9f0dea4](https://review.byted.org/#/q/9f0dea4)), closes [#1574](https://jira.bytedance.com/browse/LKI-1574)
* **email:** 详情页对接查看图片 ([3e16b53](https://review.byted.org/#/q/3e16b53)), closes [#1577](https://jira.bytedance.com/browse/LKI-1577)
* **email:** 详情页对接查看未读 ([7f1534e](https://review.byted.org/#/q/7f1534e)), closes [#1576](https://jira.bytedance.com/browse/LKI-1576)
* **email:** 详情页对接附件查看 ([17aafe0](https://review.byted.org/#/q/17aafe0)), closes [#1578](https://jira.bytedance.com/browse/LKI-1578)
* **email:** 详情页默认头像无法显示、系统消息摘要不对 ([63fc4f4](https://review.byted.org/#/q/63fc4f4)), closes [#1583](https://jira.bytedance.com/browse/LKI-1583)
* **message:** 上传日志.zip后缀没了 ([f445562](https://review.byted.org/#/q/f445562)), closes [#1582](https://jira.bytedance.com/browse/LKI-1582)
* **message:** 修复修复xss引入的新的thread详情页问题 ([6ebfe37](https://review.byted.org/#/q/6ebfe37)), closes [#1571](https://jira.bytedance.com/browse/LKI-1571)
* **message:** 修复某些组合emoji 表情后接 url 时渲染不正确的问题. ([2c75e42](https://review.byted.org/#/q/2c75e42)), closes [#1589](https://jira.bytedance.com/browse/LKI-1589)


### Features

* **email:** 对接 Rich Text ([bdccd67](https://review.byted.org/#/q/bdccd67)), closes [#1570](https://jira.bytedance.com/browse/LKI-1570)



<a name="1.2.22"></a>
## 1.2.22 (2018-02-13)


### Bug Fixes

* **core:** 修复详情页安全漏洞 && 修复ResourceDownloader crash ([2e0bb41](https://review.byted.org/#/q/2e0bb41)), closes [#1564](https://jira.bytedance.com/browse/LKI-1564)
* **email:** EmailParseHelper done ([35425e2](https://review.byted.org/#/q/35425e2)), closes [#1552](https://jira.bytedance.com/browse/LKI-1552)
* **message:** url 识别策略优化, 不主动添加scheme修改原内容, 只在跳转的时候增加 scheme ([3edff55](https://review.byted.org/#/q/3edff55)), closes [#1566](https://jira.bytedance.com/browse/LKI-1566)
* **message:** 修复已读点英文会重叠的问题 && 修复www.baidu.com在详情页点击会跳到docs的问题 ([a819c6a](https://review.byted.org/#/q/a819c6a)), closes [#1565](https://jira.bytedance.com/browse/LKI-1565)
* **message:** 修复详情页漏洞 ([a545257](https://review.byted.org/#/q/a545257)), closes [#1564](https://jira.bytedance.com/browse/LKI-1564)
* **message:** 文件转发,当源文件删除后及时修改状态 ([cda0f75](https://review.byted.org/#/q/cda0f75)), closes [#1568](https://jira.bytedance.com/browse/LKI-1568)


### Features

* **component:** 主界面点加号添加写邮件 ([cbf1db7](https://review.byted.org/#/q/cbf1db7)), closes [#755](https://jira.bytedance.com/browse/LKI-755)
* **email:** Email 编辑同步存储草稿 ([42b5a14](https://review.byted.org/#/q/42b5a14)), closes [#1447](https://jira.bytedance.com/browse/LKI-1447)
* **email:** Feed list email cell done ([a3d4096](https://review.byted.org/#/q/a3d4096)), closes [#1521](https://jira.bytedance.com/browse/LKI-1521)
* **email:** H5和Native对接回复邮件 ([c06f8e8](https://review.byted.org/#/q/c06f8e8)), closes [#1535](https://jira.bytedance.com/browse/LKI-1535)
* **email:** pack email 系统消息 trigger ([fbdf700](https://review.byted.org/#/q/fbdf700)), closes [#1516](https://jira.bytedance.com/browse/LKI-1516)
* **email:** 优化 Email Feed Cell 显示 ([78b0004](https://review.byted.org/#/q/78b0004)), closes [#1408](https://jira.bytedance.com/browse/LKI-1408)
* **email:** 优化 Email header 拖动，单行，多行模式等等 ([d2fdebc](https://review.byted.org/#/q/d2fdebc)), closes [#974](https://jira.bytedance.com/browse/LKI-974)
* **email:** 优化email at user 与收件人联动 ([9d867ba](https://review.byted.org/#/q/9d867ba)), closes [#1524](https://jira.bytedance.com/browse/LKI-1524)
* **email:** 优化Email header, 以及邮件编写界面替换为AutoLayout ([6edac21](https://review.byted.org/#/q/6edac21)), closes [#969](https://jira.bytedance.com/browse/LKI-969)
* **email:** 优化Feed email cell ([d30de0e](https://review.byted.org/#/q/d30de0e)), closes [#1526](https://jira.bytedance.com/browse/LKI-1526)
* **email:** 修正Email attachment 数据结构 ([273df9f](https://review.byted.org/#/q/273df9f)), closes [#1514](https://jira.bytedance.com/browse/LKI-1514)
* **email:** 初始化草稿中的参与者 ([f9e58b1](https://review.byted.org/#/q/f9e58b1)), closes [#1448](https://jira.bytedance.com/browse/LKI-1448)
* **email:** 回复邮件 可能 @ 的人 ([0122752](https://review.byted.org/#/q/0122752)), closes [#1563](https://jira.bytedance.com/browse/LKI-1563)
* **email:** 完善邮件附件组件 ([27f3a76](https://review.byted.org/#/q/27f3a76)), closes [#1031](https://jira.bytedance.com/browse/LKI-1031)
* **email:** 定义EmailParse AttrString转换使用的tuple ([b3bb20a](https://review.byted.org/#/q/b3bb20a)), closes [#1551](https://jira.bytedance.com/browse/LKI-1551)
* **email:** 定义用于AttributedString的对应Tag的Key ([5f6b7cb](https://review.byted.org/#/q/5f6b7cb)), closes [#1546](https://jira.bytedance.com/browse/LKI-1546)
* **email:** 微调邮件详情viewmodel，emailmodel增加subject ([bcfba61](https://review.byted.org/#/q/bcfba61)), closes [#1495](https://jira.bytedance.com/browse/LKI-1495)
* **email:** 添加发送邮件失败提示 ([2c653c6](https://review.byted.org/#/q/2c653c6)), closes [#1505](https://jira.bytedance.com/browse/LKI-1505)
* **email:** 补充邮件发送页面逻辑 ([37c34c3](https://review.byted.org/#/q/37c34c3)), closes [#1529](https://jira.bytedance.com/browse/LKI-1529)
* **email:** 解析系统消息和triggerUser ([d21589b](https://review.byted.org/#/q/d21589b)), closes [#1537](https://jira.bytedance.com/browse/LKI-1537)
* **email:** 邮件组件初始化 ([9c951cb](https://review.byted.org/#/q/9c951cb)), closes [#1399](https://jira.bytedance.com/browse/LKI-1399)
* **email:** 邮件详情页Viewmodel基本逻辑 ([636f621](https://review.byted.org/#/q/636f621)), closes [#1495](https://jira.bytedance.com/browse/LKI-1495)
* **email:** 邮件详情页面回复键盘 ([8228da9](https://review.byted.org/#/q/8228da9)), closes [#982](https://jira.bytedance.com/browse/LKI-982)
* **email:** 邮件页面回退按钮支持未读显示(同时修正chatvc过早load数据引发的view被提前加载的问题) ([4bc193e](https://review.byted.org/#/q/4bc193e)), closes [#1567](https://jira.bytedance.com/browse/LKI-1567)
* **file:** 完善Rust文件上传接口 ([4c78c0e](https://review.byted.org/#/q/4c78c0e)), closes [#983](https://jira.bytedance.com/browse/LKI-983)



<a name="1.2.21"></a>
## 1.2.21 (2018-02-11)


### Bug Fixes

* **component:** 修复Info.plist中缺少对NSPhotoLibraryAddUsageDescription的描述可能会引起崩溃的问题 ([1c2f34f](https://review.byted.org/#/q/1c2f34f)), closes [#1539](https://jira.bytedance.com/browse/LKI-1539)
* **component:** 修复多个问题 ([a19eb41](https://review.byted.org/#/q/a19eb41)), closes [#1418](https://jira.bytedance.com/browse/LKI-1418)
* 修复字符串拼接错误 ([3c7215c](https://review.byted.org/#/q/3c7215c))
* **login:** 修改获取deviceid后没有切换到主线程造成的崩溃 ([db1bc24](https://review.byted.org/#/q/db1bc24)), closes [#1538](https://jira.bytedance.com/browse/LKI-1538)
* 修复 #encoding 放在第一行导致不能运行的 BUG ([58f9770](https://review.byted.org/#/q/58f9770))
* 修复拼写错误 ([a41d086](https://review.byted.org/#/q/a41d086))
* 修复构建脚本的 BUG ([4664e7c](https://review.byted.org/#/q/4664e7c))
* **message:** badge调整为完全信赖rust,SearchRequest报错 ([3aec239](https://review.byted.org/#/q/3aec239)), closes [#1549](https://jira.bytedance.com/browse/LKI-1549)
* **message:** loadMoreMessages函数一处逻辑问题修正，导致产生错误的消息区间请求 ([29422f7](https://review.byted.org/#/q/29422f7)), closes [#1556](https://jira.bytedance.com/browse/LKI-1556)
* **message:** 保存到云盘失败弹出提示信息 ([f77c68f](https://review.byted.org/#/q/f77c68f)), closes [#1498](https://jira.bytedance.com/browse/LKI-1498)
* **message:** 修复语音消息编码格式错误的问题 ([e2c72ce](https://review.byted.org/#/q/e2c72ce)), closes [#1540](https://jira.bytedance.com/browse/LKI-1540)
* **message:** 修复转让群主后，若不退出群设置页，则依然可见群管理入口的问题 ([ffe07b9](https://review.byted.org/#/q/ffe07b9)), closes [#1555](https://jira.bytedance.com/browse/LKI-1555)


### Features

* **component:** 增加部分国际化 ([841d551](https://review.byted.org/#/q/841d551)), closes [#1510](https://jira.bytedance.com/browse/LKI-1510) [#1519](https://jira.bytedance.com/browse/LKI-1519) [#1520](https://jira.bytedance.com/browse/LKI-1520) [#1523](https://jira.bytedance.com/browse/LKI-1523)
* **message:** 修复云盘bug若干 ([eba5d7a](https://review.byted.org/#/q/eba5d7a)), closes [#1498](https://jira.bytedance.com/browse/LKI-1498)
* **message:** 修复云盘UI走查的 bug ([e70680d](https://review.byted.org/#/q/e70680d)), closes [#1498](https://jira.bytedance.com/browse/LKI-1498)
* **message:** 修复云盘UI走查的 bug ([ec8ded2](https://review.byted.org/#/q/ec8ded2)), closes [#1498](https://jira.bytedance.com/browse/LKI-1498)
* **message:** 修复云盘UI走查的 bug ([57c454f](https://review.byted.org/#/q/57c454f)), closes [#1498](https://jira.bytedance.com/browse/LKI-1498)
* **message:** 修复进入云盘文件夹乱码的问题 ([e06b334](https://review.byted.org/#/q/e06b334)), closes [#1498](https://jira.bytedance.com/browse/LKI-1498)
* **message:** 处理sdk 返回的"资源文件不存在" ([9b9c7dd](https://review.byted.org/#/q/9b9c7dd)), closes [#1498](https://jira.bytedance.com/browse/LKI-1498)
* **message:** 源文件被撤回, 弹出 toast ([fca4bc2](https://review.byted.org/#/q/fca4bc2)), closes [#1498](https://jira.bytedance.com/browse/LKI-1498)
* **web:** 打开链接支持是否在新窗口打开 ([845f440](https://review.byted.org/#/q/845f440)), closes [#1545](https://jira.bytedance.com/browse/LKI-1545)



<a name="1.2.20"></a>
## 1.2.20 (2018-02-04)


### Bug Fixes

* **message:** url渲染兼容老消息,老消息系统渲染. ([91219bb](https://review.byted.org/#/q/91219bb)), closes [#916](https://jira.bytedance.com/browse/LKI-916)
* **setting:** 修复个人中心页面使用 account 不当造成的 crash ([b4b416c](https://review.byted.org/#/q/b4b416c)), closes [#1530](https://jira.bytedance.com/browse/LKI-1530)
* **urgent:** 加急发送后会立即显示已读 ([bb8d14c](https://review.byted.org/#/q/bb8d14c)), closes [#1532](https://jira.bytedance.com/browse/LKI-1532)



<a name="1.2.20-beta9"></a>
## 1.2.20-beta9 (2018-02-01)


### Bug Fixes

* **component:** 修复App启动没有拉取电话状态BUG ([c8c709b](https://review.byted.org/#/q/c8c709b)), closes [#1509](https://jira.bytedance.com/browse/LKI-1509)
* **message:** url 预览消息 icon 太小时显示默认图片 ([9b66fb6](https://review.byted.org/#/q/9b66fb6)), closes [#916](https://jira.bytedance.com/browse/LKI-916)
* **message:** url 预览消息, 无标题时不展示预览信息. ([9fa42c5](https://review.byted.org/#/q/9fa42c5)), closes [#916](https://jira.bytedance.com/browse/LKI-916)
* **message:** 修复 url 预览消息 reaction 位置不对的问题 ([cc6e2d2](https://review.byted.org/#/q/cc6e2d2)), closes [#916](https://jira.bytedance.com/browse/LKI-916)
* **message:** 修复[ ]导致的 url 链接偏移的问题 ([5abcd9e](https://review.byted.org/#/q/5abcd9e)), closes [#916](https://jira.bytedance.com/browse/LKI-916)
* **message:** 修复@导致链接偏移错误的问题 ([cf96093](https://review.byted.org/#/q/cf96093)), closes [#916](https://jira.bytedance.com/browse/LKI-916)
* **message:** 修复iOS10一下约束冲突问题 && RustKFImageLoader hang住请求bug ([8b3e5c7](https://review.byted.org/#/q/8b3e5c7)), closes [#1501](https://jira.bytedance.com/browse/LKI-1501)
* **message:** 修复表情导致 url 渲染偏移的问题 ([7bd1b32](https://review.byted.org/#/q/7bd1b32)), closes [#916](https://jira.bytedance.com/browse/LKI-916)
* **message:** 修改发送文件UI细节，配合云盘UI改版 ([0e8f346](https://review.byted.org/#/q/0e8f346)), closes [#1503](https://jira.bytedance.com/browse/LKI-1503)
* **message:** 修正 url 预览消息有@的情况下的 offset ([8fecdf2](https://review.byted.org/#/q/8fecdf2)), closes [#916](https://jira.bytedance.com/browse/LKI-916)
* **message:** 修正多端同步自己已读状态没处理的问题 ([6b91c73](https://review.byted.org/#/q/6b91c73)), closes [#1508](https://jira.bytedance.com/browse/LKI-1508)
* **message:** 创建了多个同样的群 ([aa3d62f](https://review.byted.org/#/q/aa3d62f)), closes [#1458](https://jira.bytedance.com/browse/LKI-1458)
* **message:** 多个at标蓝有问题 ([ea95d08](https://review.byted.org/#/q/ea95d08)), closes [#1499](https://jira.bytedance.com/browse/LKI-1499)
* **message:** 暂时去掉通过 offset 和 count 来渲染 link ([5971090](https://review.byted.org/#/q/5971090)), closes [#916](https://jira.bytedance.com/browse/LKI-916)
* **thread:** 进入详情页崩溃 ([4e64e24](https://review.byted.org/#/q/4e64e24)), closes [#1518](https://jira.bytedance.com/browse/LKI-1518)


### Features

* **component:** 增加feed/群公告/消息相关国际化，群名称长度60，埋点增加同步回话数 ([19e58b8](https://review.byted.org/#/q/19e58b8)), closes [#1476](https://jira.bytedance.com/browse/LKI-1476) [#1475](https://jira.bytedance.com/browse/LKI-1475) [#1474](https://jira.bytedance.com/browse/LKI-1474) [#1028](https://jira.bytedance.com/browse/LKI-1028) [#1478](https://jira.bytedance.com/browse/LKI-1478)
* **component:** 支持在iOS客户端显示用户在workday设置的英文名字 ([567010f](https://review.byted.org/#/q/567010f)), closes [#1507](https://jira.bytedance.com/browse/LKI-1507)
* **feed:** 增加置顶埋点 ([fd4db06](https://review.byted.org/#/q/fd4db06)), closes [#1492](https://jira.bytedance.com/browse/LKI-1492)
* **message:** url 预览卡片增加点击跳转事件 ([d653899](https://review.byted.org/#/q/d653899)), closes [#916](https://jira.bytedance.com/browse/LKI-916)
* **message:** 消息中支持预览 URL 内容 ([0b12175](https://review.byted.org/#/q/0b12175)), closes [#916](https://jira.bytedance.com/browse/LKI-916)



<a name="1.2.20-beta6"></a>
## 1.2.20-beta6 (2018-01-26)


### Bug Fixes

* **feed:** sort done feeds with id when update time is equal. ([38c1d5b](https://review.byted.org/#/q/38c1d5b)), closes [#1494](https://jira.bytedance.com/browse/LKI-1494)
* **message:** 修复readyVariable状态未重置，导致后台断连情况下，点击push进会话逻辑不符合预期的问题 ([dc239a1](https://review.byted.org/#/q/dc239a1)), closes [#1486](https://jira.bytedance.com/browse/LKI-1486)
* **message:** 将sqlite库代码从lark.a库中分离，解决sqlite锁不生效的问题 ([abb248a](https://review.byted.org/#/q/abb248a)), closes [#1497](https://jira.bytedance.com/browse/LKI-1497)
* **message:** 转发chat排序及取消息时避免混入多余的假消息 ([0b9e9e9](https://review.byted.org/#/q/0b9e9e9)), closes [#1496](https://jira.bytedance.com/browse/LKI-1496)
* **thread:** 修复：详情页发图问题、人名含有空格无法正确标蓝、撤回消息消息直接消失 ([a7668eb](https://review.byted.org/#/q/a7668eb)), closes [#1499](https://jira.bytedance.com/browse/LKI-1499)
* **web:** resource key在malaita中的报错修复 ([ac91960](https://review.byted.org/#/q/ac91960)), closes [#1487](https://jira.bytedance.com/browse/LKI-1487)


### Features

* **message:** 电梯新实现 ([e6c0825](https://review.byted.org/#/q/e6c0825)), closes [#1461](https://jira.bytedance.com/browse/LKI-1461)



<a name="1.2.20-beta5"></a>
## 1.2.20-beta5 (2018-01-22)


### Bug Fixes

* **feed:** 调整在done会话接近1屏时置顶出现的动画 ([57ff224](https://review.byted.org/#/q/57ff224)), closes [#1482](https://jira.bytedance.com/browse/LKI-1482) [#1483](https://jira.bytedance.com/browse/LKI-1483)
* **message:** findmissingmessage的crash，messagedetail聚合消息的crash，为chat拼接失败消息 ([d4537f0](https://review.byted.org/#/q/d4537f0)), closes [#1465](https://jira.bytedance.com/browse/LKI-1465)
* **message:** Orientation为1的拍照，显示时是按照1显示，但是size是按照2计算 ([73fa51c](https://review.byted.org/#/q/73fa51c)), closes [#1470](https://jira.bytedance.com/browse/LKI-1470)
* **message:** retrieveImageInDiskCache:  [Error| APIError: 未知的业务错误类型(RustSDk) ([1df0a50](https://review.byted.org/#/q/1df0a50)), closes [#1468](https://jira.bytedance.com/browse/LKI-1468)
* **message:** 修正userpacker逻辑错误 ([a9616ab](https://review.byted.org/#/q/a9616ab)), closes [#1459](https://jira.bytedance.com/browse/LKI-1459)
* **message:** 发消息全部走异步接口 ([1073ba7](https://review.byted.org/#/q/1073ba7)), closes [#1464](https://jira.bytedance.com/browse/LKI-1464)
* **message:** 解决点击本地推送，进入会话badge无法消除的问题 ([ac24f14](https://review.byted.org/#/q/ac24f14)), closes [#1477](https://jira.bytedance.com/browse/LKI-1477)
* **search:** 修正首页二级搜索页，搜索失败提示不正确的问题 ([5a01582](https://review.byted.org/#/q/5a01582)), closes [#1481](https://jira.bytedance.com/browse/LKI-1481)
* **setting:** 没有设置过语言则按照系统语言国际化. ([456bc03](https://review.byted.org/#/q/456bc03)), closes [#1463](https://jira.bytedance.com/browse/LKI-1463)
* **web:** Native支持H5中Post的图片走lark-resource && 详情页 resource key报错解决 ([4c36776](https://review.byted.org/#/q/4c36776)), closes [#1484](https://jira.bytedance.com/browse/LKI-1484)


### Features

* **message:** 支持获取chat未读at消息接口 ([a1f8f20](https://review.byted.org/#/q/a1f8f20)), closes [#1462](https://jira.bytedance.com/browse/LKI-1462)
* **web:** 拦截详情页图片请求，使用kingfisher处理 ([16aa038](https://review.byted.org/#/q/16aa038)), closes [#1460](https://jira.bytedance.com/browse/LKI-1460)



<a name="1.2.20-beta3"></a>
## 1.2.20-beta3 (2018-01-18)


### Bug Fixes

* **chat:** 创建了多个同样的群 ([558d614](https://review.byted.org/#/q/558d614)), closes [#1458](https://jira.bytedance.com/browse/LKI-1458)
* **message:** chatVc voicemanager getter的crash ([bd69fad](https://review.byted.org/#/q/bd69fad)), closes [#1058](https://jira.bytedance.com/browse/LKI-1058)
* **rust:** 修复读取首页组织结构APIError生成不正确的问题 ([8cb33ce](https://review.byted.org/#/q/8cb33ce)), closes [#1452](https://jira.bytedance.com/browse/LKI-1452)
* **rust:** 当用户没有授权接收推送消息时候打印日志级别由error调整到debug ([8410604](https://review.byted.org/#/q/8410604)), closes [#1453](https://jira.bytedance.com/browse/LKI-1453)
* **setting:** lark iOS 升级流程变更, 直接使用服务端返回的 itms-service 下载链接 ([e8f4aec](https://review.byted.org/#/q/e8f4aec)), closes [#1456](https://jira.bytedance.com/browse/LKI-1456)



<a name="1.2.20-beta2"></a>
## 1.2.20-beta2 (2018-01-16)


### Bug Fixes

* **component:** 搜索取消按钮和建群确认按钮大小不对 ([38212c2](https://review.byted.org/#/q/38212c2)), closes [#1451](https://jira.bytedance.com/browse/LKI-1451)
* **rust:** 修复进详情页crash、详情页撤回消息显示不对、没有消息时拉取消息会crash ([fd5b879](https://review.byted.org/#/q/fd5b879)), closes [#1449](https://jira.bytedance.com/browse/LKI-1449)



<a name="1.2.19"></a>
## 1.2.19 (2018-01-15)


### Bug Fixes

* **chat:** 群主权限增加对群公告的权限 ([1cef05a](https://review.byted.org/#/q/1cef05a)), closes [#1439](https://jira.bytedance.com/browse/LKI-1439)
* **component:** 修复看图相关Bug三处 ([0ebce81](https://review.byted.org/#/q/0ebce81)), closes [#1440](https://jira.bytedance.com/browse/LKI-1440)
* **login:** 调整扫一扫接口错误码捕获范围 ([32aa20c](https://review.byted.org/#/q/32aa20c)), closes [#1427](https://jira.bytedance.com/browse/LKI-1427)
* **message:** at绿点先变绿再变灰逻辑调整 ([fca16cd](https://review.byted.org/#/q/fca16cd)), closes [#1421](https://jira.bytedance.com/browse/LKI-1421)
* **message:** putReadMessages缺少参数序列化错误 ([91cf5d0](https://review.byted.org/#/q/91cf5d0)), closes [#1444](https://jira.bytedance.com/browse/LKI-1444)
* **message:** QuasiMessage转MessageMemberRef错误 ([93a4df6](https://review.byted.org/#/q/93a4df6)), closes [#1421](https://jira.bytedance.com/browse/LKI-1421)
* **message:** rust版本在WiFi和移动网络（4g、3g、2g）下的图片压缩体积阈值改成500k和300k ([09fc35d](https://review.byted.org/#/q/09fc35d)), closes [#1318](https://jira.bytedance.com/browse/LKI-1318)
* **message:** 修复单聊已读灰点未变绿的问题 ([2a027fe](https://review.byted.org/#/q/2a027fe)), closes [#1432](https://jira.bytedance.com/browse/LKI-1432)
* **message:** 修复图片打点时间问题 ([78a49b6](https://review.byted.org/#/q/78a49b6)), closes [#1333](https://jira.bytedance.com/browse/LKI-1333)
* **message:** 解决PersonalCardVC大图模糊的问题 ([fe2ef9d](https://review.byted.org/#/q/fe2ef9d)), closes [#1425](https://jira.bytedance.com/browse/LKI-1425)
* **message:** 解决头像设置，如果没有头像的url则无法设置头像的问题 ([4bb9ad9](https://review.byted.org/#/q/4bb9ad9)), closes [#1423](https://jira.bytedance.com/browse/LKI-1423)
* **setting:** 修复国际化后设置页,扫描菜单页文字过长截断的问题. ([402c8e5](https://review.byted.org/#/q/402c8e5)), closes [#1090](https://jira.bytedance.com/browse/LKI-1090)
* **urgent:** 详情页加急传的message传成rootmessage了 ([010d8e8](https://review.byted.org/#/q/010d8e8)), closes [#1446](https://jira.bytedance.com/browse/LKI-1446)
* **web:** iOS9无法加载应用中心 ([876ebbb](https://review.byted.org/#/q/876ebbb)), closes [#1424](https://jira.bytedance.com/browse/LKI-1424)


### Features

* **component:** 使用新的voip加密 ([cfd8b2e](https://review.byted.org/#/q/cfd8b2e)), closes [#1353](https://jira.bytedance.com/browse/LKI-1353)
* **component:** 拨打电话前增加提示弹框 ([c1fb948](https://review.byted.org/#/q/c1fb948)), closes [#1409](https://jira.bytedance.com/browse/LKI-1409)
* **feed:** 完成快速跳转 badge 逻辑 ([36d3f2e](https://review.byted.org/#/q/36d3f2e)), closes [#1416](https://jira.bytedance.com/browse/LKI-1416)
* **feed:** 快速跳转长按气泡提示 ([517c453](https://review.byted.org/#/q/517c453)), closes [#1417](https://jira.bytedance.com/browse/LKI-1417)
* **setting:** 办公套件在iOS上支持多语言的框架 ([103d9eb](https://review.byted.org/#/q/103d9eb)), closes [#1090](https://jira.bytedance.com/browse/LKI-1090)
* **urgent:** 加急一条消息时，默认选中@了的且此时未读的人 ([a09cdcd](https://review.byted.org/#/q/a09cdcd)), closes [#1108](https://jira.bytedance.com/browse/LKI-1108)


### Performance Improvements

* **message:** 提升发图片消息性能，不在主线程发消息 && RustMessageAPI 有序返回数组 ([2e712c2](https://review.byted.org/#/q/2e712c2)), closes [#1419](https://jira.bytedance.com/browse/LKI-1419)



<a name="1.2.18"></a>
## 1.2.18 (2018-01-09)


### Bug Fixes

* **chat:** 从chatViewController滑动返回feedListViewController的时候，title位置会抖动 ([1790122](https://review.byted.org/#/q/1790122)), closes [#1396](https://jira.bytedance.com/browse/LKI-1396)
* **contact:** 修正部门名称过长，cell截断的问题 ([ef8fcc8](https://review.byted.org/#/q/ef8fcc8)), closes [#1384](https://jira.bytedance.com/browse/LKI-1384)
* **feed:** PushMessage处理FeedCard，从done中移回来 ([4dbf3bc](https://review.byted.org/#/q/4dbf3bc)), closes [#1403](https://jira.bytedance.com/browse/LKI-1403)
* **feed:** 加急时间显示不对 ([1843279](https://review.byted.org/#/q/1843279)), closes [#1415](https://jira.bytedance.com/browse/LKI-1415)
* **feed:** 双击tab调到回话定位不准 ([ba6a96a](https://review.byted.org/#/q/ba6a96a)), closes [#1402](https://jira.bytedance.com/browse/LKI-1402)
* **feed:** 解决Feed滚动设置头像卡顿问题 ([fee9fb6](https://review.byted.org/#/q/fee9fb6)), closes [#1404](https://jira.bytedance.com/browse/LKI-1404)
* **feed:** 设置图片走异步 ([47a4706](https://review.byted.org/#/q/47a4706))
* **login:** 解析/显示session信息中的renewalTime ([0a22246](https://review.byted.org/#/q/0a22246)), closes [#1405](https://jira.bytedance.com/browse/LKI-1405)
* **message:** readMemberIds逻辑清理 ([9111ed6](https://review.byted.org/#/q/9111ed6)), closes [#1412](https://jira.bytedance.com/browse/LKI-1412)
* **message:** 修复对已删除或者已撤回消息还进行消息实体解析的问题 ([bee0c55](https://review.byted.org/#/q/bee0c55)), closes [#1390](https://jira.bytedance.com/browse/LKI-1390)
* **message:** 修改聊天内文件打不开的问题 ([86cee1f](https://review.byted.org/#/q/86cee1f)), closes [#1386](https://jira.bytedance.com/browse/LKI-1386)
* **message:** 包含空格，拨打电话失败；图片二维码无法识别；日志名称格式修改； ([58959e6](https://review.byted.org/#/q/58959e6)), closes [#1365](https://jira.bytedance.com/browse/LKI-1365) [#1372](https://jira.bytedance.com/browse/LKI-1372) [#1391](https://jira.bytedance.com/browse/LKI-1391)
* **message:** 图片及时上墙逻辑补充 ([5b271b8](https://review.byted.org/#/q/5b271b8))
* **message:** 提升发送文件，从相册导出视频的质量，从medium改为high ([be32ae1](https://review.byted.org/#/q/be32ae1)), closes [#1074](https://jira.bytedance.com/browse/LKI-1074)
* **message:** 搜索数据加载时奔溃 ([6fa9550](https://review.byted.org/#/q/6fa9550)), closes [#1414](https://jira.bytedance.com/browse/LKI-1414)
* **message:** 消息资源请求不带token就不发请求 ([741cc8f](https://review.byted.org/#/q/741cc8f)), closes [#1400](https://jira.bytedance.com/browse/LKI-1400)
* **message:** 解决message push可能不带user、parent、root的问题 ([c4ac51c](https://review.byted.org/#/q/c4ac51c)), closes [#1392](https://jira.bytedance.com/browse/LKI-1392)
* **web:** window.open支持相对路径 ([dbd2618](https://review.byted.org/#/q/dbd2618)), closes [#1413](https://jira.bytedance.com/browse/LKI-1413)
* **web:** 修改doc内部滑动返回，触发navigationViewController滑动返回的问题 ([ef40bdf](https://review.byted.org/#/q/ef40bdf)), closes [#1388](https://jira.bytedance.com/browse/LKI-1388)


### Features

* **rust:** 接入Rust Call ([b63e008](https://review.byted.org/#/q/b63e008)), closes [#1287](https://jira.bytedance.com/browse/LKI-1287)


### Performance Improvements

* **component:** 启动之后首页卡顿 ([2e1bc82](https://review.byted.org/#/q/2e1bc82)), closes [#1371](https://jira.bytedance.com/browse/LKI-1371)



<a name="1.2.17"></a>
## 1.2.17 (2018-01-03)


### Bug Fixes

* **chat:** 客服群关闭转让群入口 ([ef1e59d](https://review.byted.org/#/q/ef1e59d)), closes [#1379](https://jira.bytedance.com/browse/LKI-1379)
* **web:** 在profile页点击OKR、头条圈会提示无法打开链接 ([4f18a04](https://review.byted.org/#/q/4f18a04)), closes [#1374](https://jira.bytedance.com/browse/LKI-1374)


### Features

* **feed:** 会话“打开”和“关闭”快捷跳转接口提供 ([33efb0b](https://review.byted.org/#/q/33efb0b)), closes [#1179](https://jira.bytedance.com/browse/LKI-1179)



<a name="1.2.16"></a>
## 1.2.16 (2018-01-02)


### Bug Fixes

* **auth:** 重登陆清楚全部cookie ([763ff15](https://review.byted.org/#/q/763ff15))
* **chat:** 只能群主减人 ([d0f4309](https://review.byted.org/#/q/d0f4309)), closes [#1032](https://jira.bytedance.com/browse/LKI-1032)
* **chat:** 群主权限暂时去掉修改公告的限制 ([c885cf6](https://review.byted.org/#/q/c885cf6)), closes [#1036](https://jira.bytedance.com/browse/LKI-1036)
* **chat:** 群公告暂时打开编辑权限 ([6e4b0ad](https://review.byted.org/#/q/6e4b0ad)), closes [#1032](https://jira.bytedance.com/browse/LKI-1032)
* **chat:** 转让群增加"转让并退出"逻辑 ([7b8f487](https://review.byted.org/#/q/7b8f487)), closes [#1032](https://jira.bytedance.com/browse/LKI-1032)
* **component:** 修复collection size 崩溃 ([e6f4755](https://review.byted.org/#/q/e6f4755)), closes [#1034](https://jira.bytedance.com/browse/LKI-1034)
* **contact:** 群聊搜索联系人列表负责人 icon 替换 ([a30a480](https://review.byted.org/#/q/a30a480)), closes [#1339](https://jira.bytedance.com/browse/LKI-1339)
* **contact:** 补回namepy字段解析逻辑 ([8c4bf7e](https://review.byted.org/#/q/8c4bf7e)), closes [#1006](https://jira.bytedance.com/browse/LKI-1006)
* **feed:** 点A会话进去是B会话以及done错会话 ([71a3ffc](https://review.byted.org/#/q/71a3ffc)), closes [#1373](https://jira.bytedance.com/browse/LKI-1373)
* **message:** chatViewController topMessageId carsh修复 ([5d078c6](https://review.byted.org/#/q/5d078c6)), closes [#1363](https://jira.bytedance.com/browse/LKI-1363)
* **message:** ChatViewController.newMessageCountChanged crash修复 ([1eb5f93](https://review.byted.org/#/q/1eb5f93)), closes [#1359](https://jira.bytedance.com/browse/LKI-1359)
* **message:** ChatViewController.tableView crash修复 ([5f2a642](https://review.byted.org/#/q/5f2a642)), closes [#1366](https://jira.bytedance.com/browse/LKI-1366)
* **message:** messageViewModel loadMoreMessages crash修复 ([c6aea85](https://review.byted.org/#/q/c6aea85)), closes [#1361](https://jira.bytedance.com/browse/LKI-1361)
* **message:** 从push进入有更多新消息但是没有上提加载 ([9b240ec](https://review.byted.org/#/q/9b240ec)), closes [#1368](https://jira.bytedance.com/browse/LKI-1368)
* **message:** 修改视频附件发送，UI走查问题 ([5412984](https://review.byted.org/#/q/5412984)), closes [#1571](https://jira.bytedance.com/browse/LKI-1571)
* **message:** 删除TTTracker的高频日志输出 ([e50dda1](https://review.byted.org/#/q/e50dda1)), closes [#1362](https://jira.bytedance.com/browse/LKI-1362)
* **message:** 去掉后台tracerManager.resetTerminalInfo调用 ([44e75f6](https://review.byted.org/#/q/44e75f6)), closes [#1234](https://jira.bytedance.com/browse/LKI-1234)
* **message:** 变更打点策略，GA继续上报category字段，TEE过滤掉 ([4c5975c](https://review.byted.org/#/q/4c5975c)), closes [#1234](https://jira.bytedance.com/browse/LKI-1234)
* **message:** 尝试解决RootParentPacker crash的问题 ([66e6724](https://review.byted.org/#/q/66e6724))
* **message:** 拨打张一鸣电话提示弹框消失太快, 消息详情页撤回消息增加弹窗提示 ([f8a5908](https://review.byted.org/#/q/f8a5908)), closes [#1350](https://jira.bytedance.com/browse/LKI-1350)
* **message:** 撤回的帖子消息还可以看到标题 ([68e7097](https://review.byted.org/#/q/68e7097)), closes [#1369](https://jira.bytedance.com/browse/LKI-1369)
* **message:** 每次客户端重启后，都会从日志文件的第一行进行输出，造成日志丢失 ([6421452](https://review.byted.org/#/q/6421452)), closes [#1360](https://jira.bytedance.com/browse/LKI-1360)
* **message:** 调整发送消息PutMessage请求的超时时间，由10秒增加到90秒，保持retryCount=0的设定 ([4ac9bfc](https://review.byted.org/#/q/4ac9bfc)), closes [#1358](https://jira.bytedance.com/browse/LKI-1358)
* **web:** docs导航滑动返回时按钮颜色不对 ([a4f8a0c](https://review.byted.org/#/q/a4f8a0c)), closes [#1354](https://jira.bytedance.com/browse/LKI-1354)


### Features

* **chat:** 新增群主权限管理功能 ([d6ea381](https://review.byted.org/#/q/d6ea381)), closes [#1036](https://jira.bytedance.com/browse/LKI-1036)
* **chat:** 无权限编辑群资料时只展示 ([4918914](https://review.byted.org/#/q/4918914)), closes [#1191](https://jira.bytedance.com/browse/LKI-1191)
* **chat:** 转让群主界面修改 ([56ec19b](https://review.byted.org/#/q/56ec19b)), closes [#1192](https://jira.bytedance.com/browse/LKI-1192)
* **component:** 修正网络电话加密算法 ([df504d2](https://review.byted.org/#/q/df504d2)), closes [#1353](https://jira.bytedance.com/browse/LKI-1353)
* **component:** 添加电话版本低提示 ([97ef705](https://review.byted.org/#/q/97ef705)), closes [#1370](https://jira.bytedance.com/browse/LKI-1370)
* **component:** 账号与设备页面支持修改个人头像 ([4945f3a](https://review.byted.org/#/q/4945f3a)), closes [#1367](https://jira.bytedance.com/browse/LKI-1367)
* **feed:** 会话支持快速跳转 ([c15bc03](https://review.byted.org/#/q/c15bc03)), closes [#1078](https://jira.bytedance.com/browse/LKI-1078) [#1180](https://jira.bytedance.com/browse/LKI-1180) [#1183](https://jira.bytedance.com/browse/LKI-1183) [#1185](https://jira.bytedance.com/browse/LKI-1185)


### Performance Improvements

* **message:** pushhandler在其他线程处理数据 ([d0f8d1b](https://review.byted.org/#/q/d0f8d1b)), closes [#1371](https://jira.bytedance.com/browse/LKI-1371)



<a name="1.2.16-beta2"></a>
## 1.2.16-beta2 (2017-12-28)


### Bug Fixes

* **chat:** 修复移动端图片超过50*50px时图片会被拉伸的问题 ([7f7cc99](https://review.byted.org/#/q/7f7cc99)), closes [#1282](https://jira.bytedance.com/browse/LKI-1282)
* **component:** 修复头像替换时，底部按钮点击延迟 ([d527c0a](https://review.byted.org/#/q/d527c0a)), closes [#1072](https://jira.bytedance.com/browse/LKI-1072)
* **component:** 修改设置navigationBar的tintcolor, 然而barButtonItem不生效的问题 ([aeedf02](https://review.byted.org/#/q/aeedf02)), closes [#1338](https://jira.bytedance.com/browse/LKI-1338)
* **component:** 首页接入头像变更 ([9b730e8](https://review.byted.org/#/q/9b730e8)), closes [#1340](https://jira.bytedance.com/browse/LKI-1340)
* **setting:** 替换图标, 修复部分潜在问题. ([230a3bb](https://review.byted.org/#/q/230a3bb)), closes [#1339](https://jira.bytedance.com/browse/LKI-1339)
* **web:** 修复docs sdk代理问题 ([ea34518](https://review.byted.org/#/q/ea34518)), closes [#1344](https://jira.bytedance.com/browse/LKI-1344)


### Features

* **email:** 邮件header ([e50e4fb](https://review.byted.org/#/q/e50e4fb)), closes [#974](https://jira.bytedance.com/browse/LKI-974)
* **login:** 二维码扫码支持新的错误码解析 ([f9ec277](https://review.byted.org/#/q/f9ec277)), closes [#1322](https://jira.bytedance.com/browse/LKI-1322)
* **message:** 支持第三方应用分享内容到lark ([66d3b68](https://review.byted.org/#/q/66d3b68)), closes [#1255](https://jira.bytedance.com/browse/LKI-1255)


### Performance Improvements

* **setting:** 修复重连网络时多次打 end 事件的问题. ([ec88f99](https://review.byted.org/#/q/ec88f99)), closes [#1327](https://jira.bytedance.com/browse/LKI-1327)



<a name="1.2.16-beta1"></a>
## 1.2.16-beta1 (2017-12-25)


### Bug Fixes

* **chat:** 全部读了还是会出现at信息 ([76ec744](https://review.byted.org/#/q/76ec744)), closes [#1304](https://jira.bytedance.com/browse/LKI-1304)
* **component:** 头像上传完成留在预览页面 ([46f45da](https://review.byted.org/#/q/46f45da)), closes [#1332](https://jira.bytedance.com/browse/LKI-1332)
* **component:** 裁切页点击取消应该回到图片选择页 ([ff05ddf](https://review.byted.org/#/q/ff05ddf)), closes [#1072](https://jira.bytedance.com/browse/LKI-1072)
* **message:** 修复DraftCache没有初始化的问题 ([60065e6](https://review.byted.org/#/q/60065e6)), closes [#1324](https://jira.bytedance.com/browse/LKI-1324)
* **message:** 修复会话列表与聊天页面已读未读状态不同步的问题 ([8be81db](https://review.byted.org/#/q/8be81db)), closes [#1321](https://jira.bytedance.com/browse/LKI-1321)
* **message:** 打电话消息user被刷回去了 ([baa91ed](https://review.byted.org/#/q/baa91ed)), closes [#1334](https://jira.bytedance.com/browse/LKI-1334)
* **message:** 转发给自己的消息是未读状态 ([447ada8](https://review.byted.org/#/q/447ada8)), closes [#1313](https://jira.bytedance.com/browse/LKI-1313)


### Features

* **component:** 从wkwebview迁移到uiwebview ([1f99535](https://review.byted.org/#/q/1f99535)), closes [#1320](https://jira.bytedance.com/browse/LKI-1320)
* **component:** 支持更换群头像和个人头像 ([3b4a6e3](https://review.byted.org/#/q/3b4a6e3)), closes [#1069](https://jira.bytedance.com/browse/LKI-1069) [#1070](https://jira.bytedance.com/browse/LKI-1070) [#1072](https://jira.bytedance.com/browse/LKI-1072) [#1082](https://jira.bytedance.com/browse/LKI-1082) [#1084](https://jira.bytedance.com/browse/LKI-1084)
* **component:** 联系人页面中负责人标签更换 ([1eb419a](https://review.byted.org/#/q/1eb419a)), closes [#1325](https://jira.bytedance.com/browse/LKI-1325)
* **message:** 附件发送功能 ([1c1e040](https://review.byted.org/#/q/1c1e040)), closes [#1074](https://jira.bytedance.com/browse/LKI-1074)



<a name="1.2.15"></a>
## 1.2.15 (2017-12-19)


### Bug Fixes

* **message:** 修复详情页图片无法查看 ([f489c39](https://review.byted.org/#/q/f489c39)), closes [#1311](https://jira.bytedance.com/browse/LKI-1311)



<a name="1.2.14"></a>
## 1.2.14 (2017-12-19)


### Bug Fixes

* **chat:** at没有消除 ([8a7de32](https://review.byted.org/#/q/8a7de32)), closes [#1304](https://jira.bytedance.com/browse/LKI-1304)
* **chat:** Lark在后台，收到一个会话的@消息，然后再收到另一条普通消息，打开Lark，此时@消息预览不见了 ([44f878d](https://review.byted.org/#/q/44f878d)), closes [#1304](https://jira.bytedance.com/browse/LKI-1304)
* **component:** 修复蓝牙配置造成的无法录音的bug ([9dfc893](https://review.byted.org/#/q/9dfc893)), closes [#1300](https://jira.bytedance.com/browse/LKI-1300)
* **login:** 增加日志定位经常被登出的问题 ([907fcad](https://review.byted.org/#/q/907fcad)), closes [#1309](https://jira.bytedance.com/browse/LKI-1309)
* **message:** 修复上几个版本下拉刷新随机crash的问题 ([17e7adf](https://review.byted.org/#/q/17e7adf)), closes [#1310](https://jira.bytedance.com/browse/LKI-1310)
* **message:** 老版本已存在加密图无法在新版本下正常显示 ([81ecb67](https://review.byted.org/#/q/81ecb67)), closes [#1301](https://jira.bytedance.com/browse/LKI-1301)
* **message:** 解决1.2.13看大图显示的是缩略图的问题 ([9f0d335](https://review.byted.org/#/q/9f0d335)), closes [#1302](https://jira.bytedance.com/browse/LKI-1302)
* **message:** 读消息crash ([0f11c84](https://review.byted.org/#/q/0f11c84)), closes [#1308](https://jira.bytedance.com/browse/LKI-1308)



<a name="1.2.13-1064"></a>
## 1.2.13-1064 (2017-12-19)


### Bug Fixes

* **chat:** 优化会话过多导致进入转发界面延时严重的问题. ([852916e](https://review.byted.org/#/q/852916e)), closes [#1239](https://jira.bytedance.com/browse/LKI-1239)
* **chat:** 优化群公告 UI ([d23e039](https://review.byted.org/#/q/d23e039)), closes [#1283](https://jira.bytedance.com/browse/LKI-1283)
* **chat:** 群公告链接样式和点击效果做成与聊天界面一致. ([1f8d7c4](https://review.byted.org/#/q/1f8d7c4)), closes [#1283](https://jira.bytedance.com/browse/LKI-1283)
* **chat:** 群名片展示增加行间距 ([4c7da85](https://review.byted.org/#/q/4c7da85)), closes [#1283](https://jira.bytedance.com/browse/LKI-1283)
* **component:** 修正部分蓝牙耳机无法录音问题 ([a694bbd](https://review.byted.org/#/q/a694bbd)), closes [#1300](https://jira.bytedance.com/browse/LKI-1300)
* **messaeg:** 修复replyView丢失已删除处理的逻辑 && message-detail更到最新 ([f6988b2](https://review.byted.org/#/q/f6988b2))
* **message:** 修复富文本编辑草稿存储问题 ([dcfcb58](https://review.byted.org/#/q/dcfcb58)), closes [#1228](https://jira.bytedance.com/browse/LKI-1228)
* **message:** 修复本地加密图片无法读取导致重新下载的问题 ([38fe8e8](https://review.byted.org/#/q/38fe8e8))
* **message:** 修复自己加密图的相关bug ([6a097de](https://review.byted.org/#/q/6a097de)), closes [#1297](https://jira.bytedance.com/browse/LKI-1297)
* **message:** 关闭库的code coverage属性 ([a06d5ad](https://review.byted.org/#/q/a06d5ad)), closes [#1234](https://jira.bytedance.com/browse/LKI-1234)
* **message:** 删除二期一些问题修改 ([081104c](https://review.byted.org/#/q/081104c)), closes [#1248](https://jira.bytedance.com/browse/LKI-1248)
* **message:** 删除消息两处小问题修改 ([11b721f](https://review.byted.org/#/q/11b721f)), closes [#1248](https://jira.bytedance.com/browse/LKI-1248)
* **message:** 去除掉lark_version_name，lark_version_code，user_department ([167b03d](https://review.byted.org/#/q/167b03d)), closes [#1234](https://jira.bytedance.com/browse/LKI-1234)
* **message:** 名称过长的情况下水印重叠 ([e41c7ea](https://review.byted.org/#/q/e41c7ea)), closes [#1263](https://jira.bytedance.com/browse/LKI-1263)
* **message:** 增加日志打点接口，提交单元测试验证后的实现 ([1faa4d2](https://review.byted.org/#/q/1faa4d2)), closes [#1234](https://jira.bytedance.com/browse/LKI-1234)
* **message:** 建群时去掉必选成员的限制，1人即可建群 ([5bac413](https://review.byted.org/#/q/5bac413)), closes [#1250](https://jira.bytedance.com/browse/LKI-1250)
* **message:** 拉取远程消息，添加上失败消息 ([9b35fcd](https://review.byted.org/#/q/9b35fcd)), closes [#1280](https://jira.bytedance.com/browse/LKI-1280)
* **message:** 数据库升级清楚之前已删除的消息 ([9f656fa](https://review.byted.org/#/q/9f656fa)), closes [#1298](https://jira.bytedance.com/browse/LKI-1298)
* **message:** 没有未读消息气泡还在的bug ([5d2e7ec](https://review.byted.org/#/q/5d2e7ec)), closes [#1251](https://jira.bytedance.com/browse/LKI-1251)
* **message:** 解决AssetBrowser无法处理多张加密大图的问题 ([34e3848](https://review.byted.org/#/q/34e3848))
* **message:** 解决larkDev，target连接失败的问题 ([1c26380](https://review.byted.org/#/q/1c26380)), closes [#1234](https://jira.bytedance.com/browse/LKI-1234)
* **message:** 解决打点导致的发送消息崩溃问题 ([31be000](https://review.byted.org/#/q/31be000)), closes [#1292](https://jira.bytedance.com/browse/LKI-1292)
* **message:** 调整大点库到最新的2.2，增加TTTracker.framework ([7c50575](https://review.byted.org/#/q/7c50575)), closes [#1234](https://jira.bytedance.com/browse/LKI-1234)
* **web:** 修改员工Wifi应用打不开的问题 ([5e1be95](https://review.byted.org/#/q/5e1be95)), closes [#1010](https://jira.bytedance.com/browse/LKI-1010)
* **web:** 应用中心问题修复、tab icon更新、头条圈发图问题修复 ([435d921](https://review.byted.org/#/q/435d921)), closes [#1063](https://jira.bytedance.com/browse/LKI-1063) [#1261](https://jira.bytedance.com/browse/LKI-1261)


### Features

* **chat:** 值班号列表不显示描述 ([48e956f](https://review.byted.org/#/q/48e956f)), closes [#1093](https://jira.bytedance.com/browse/LKI-1093)
* **chat:** 值班号实现 ([d45500e](https://review.byted.org/#/q/d45500e)), closes [#1093](https://jira.bytedance.com/browse/LKI-1093)
* **chat:** 新增群公告功能 ([d1260a7](https://review.byted.org/#/q/d1260a7)), closes [#1067](https://jira.bytedance.com/browse/LKI-1067)
* **component:** 升级VoIP ([ccd4be3](https://review.byted.org/#/q/ccd4be3)), closes [#1276](https://jira.bytedance.com/browse/LKI-1276)
* **component:** 头条圈页面增加双击屏幕顶部，feed滚动到顶部的功能 ([a02ceb6](https://review.byted.org/#/q/a02ceb6)), closes [#1117](https://jira.bytedance.com/browse/LKI-1117)
* **message:** 优化表情滑动 ([0613d9b](https://review.byted.org/#/q/0613d9b)), closes [#1203](https://jira.bytedance.com/browse/LKI-1203)
* **message:** 修改拉取消息 ([7df4599](https://review.byted.org/#/q/7df4599)), closes [#1280](https://jira.bytedance.com/browse/LKI-1280)
* **message:** 删除消息增加弹窗确认 ([86222f8](https://review.byted.org/#/q/86222f8)), closes [#1267](https://jira.bytedance.com/browse/LKI-1267)
* **message:** 发送图片消息接入加密解密逻辑，修复发图bug ([b49785f](https://review.byted.org/#/q/b49785f)), closes [#1269](https://jira.bytedance.com/browse/LKI-1269) [#1272](https://jira.bytedance.com/browse/LKI-1272)
* **message:** 增加支持聚合多个打点数据合并的接口 ([e6f2db0](https://review.byted.org/#/q/e6f2db0)), closes [#1234](https://jira.bytedance.com/browse/LKI-1234)
* **message:** 对接删除(撤回)push及删除消息接口 ([6ff42ab](https://review.byted.org/#/q/6ff42ab)), closes [#1274](https://jira.bytedance.com/browse/LKI-1274)
* **message:** 数据库升级rename方法修正 ([77e93cf](https://review.byted.org/#/q/77e93cf)), closes [#1275](https://jira.bytedance.com/browse/LKI-1275)
* **message:** 水印策略优化,没有电话号码以邮箱名做后缀 ([5385763](https://review.byted.org/#/q/5385763)), closes [#1105](https://jira.bytedance.com/browse/LKI-1105)
* **message:** 资源登记表 ([ea548b2](https://review.byted.org/#/q/ea548b2)), closes [#1275](https://jira.bytedance.com/browse/LKI-1275)
* **rust:** rust 接入 draft ([8e9d2e2](https://review.byted.org/#/q/8e9d2e2)), closes [#1288](https://jira.bytedance.com/browse/LKI-1288)
* **rust:** 完成AppCenterAPI ([52beef2](https://review.byted.org/#/q/52beef2)), closes [#1290](https://jira.bytedance.com/browse/LKI-1290)
* **rust:** 完成OncallAPI ([7e43fdf](https://review.byted.org/#/q/7e43fdf)), closes [#1291](https://jira.bytedance.com/browse/LKI-1291)
* **rust:** 添加 rust sticker api ([a9cdff1](https://review.byted.org/#/q/a9cdff1)), closes [#1286](https://jira.bytedance.com/browse/LKI-1286)



<a name="1.2.12-1015"></a>
## 1.2.12-1015 (2017-12-12)


### Bug Fixes

* **login:** 修改新增Localizable字符串定义未加分号的问题 ([ba967c9](https://review.byted.org/#/q/ba967c9)), closes [#1233](https://jira.bytedance.com/browse/LKI-1233)
* **login:** 获取验证码接口返回Error处理 ([f3f911c](https://review.byted.org/#/q/f3f911c)), closes [#1233](https://jira.bytedance.com/browse/LKI-1233)
* **message:** chatVC进入滚动问题修复 ([b541e61](https://review.byted.org/#/q/b541e61)), closes [#1224](https://jira.bytedance.com/browse/LKI-1224)
* **message:** push来的点赞我不是排在最前面 ([7907ed6](https://review.byted.org/#/q/7907ed6)), closes [#1237](https://jira.bytedance.com/browse/LKI-1237)
* **message:** 以下是新消息标线问题 ([85c6265](https://review.byted.org/#/q/85c6265)), closes [#1240](https://jira.bytedance.com/browse/LKI-1240)
* **message:** 修复新消息数导致收发消息的bug ([a2b54c8](https://review.byted.org/#/q/a2b54c8)), closes [#1240](https://jira.bytedance.com/browse/LKI-1240)
* **message:** 修复网络电话传参数错误 ([3f4cf64](https://review.byted.org/#/q/3f4cf64)), closes [#1163](https://jira.bytedance.com/browse/LKI-1163)
* **message:** 发消息后，长时间转圈，打开其他app失效 ([1627e64](https://review.byted.org/#/q/1627e64)), closes [#1220](https://jira.bytedance.com/browse/LKI-1220)
* **message:** 拉取消息有时候网络回调在异步导致UI异常 ([4296f2b](https://review.byted.org/#/q/4296f2b)), closes [#1243](https://jira.bytedance.com/browse/LKI-1243)
* **message:** 撤回删除消息相关bug修复 ([97a090d](https://review.byted.org/#/q/97a090d)), closes [#1241](https://jira.bytedance.com/browse/LKI-1241)
* **message:** 数据加载异步导致白屏 ([6f6f36e](https://review.byted.org/#/q/6f6f36e)), closes [#1243](https://jira.bytedance.com/browse/LKI-1243)
* **message:** 文件消息增加状态显示 ([33ea069](https://review.byted.org/#/q/33ea069)), closes [#1238](https://jira.bytedance.com/browse/LKI-1238)
* **message:** 新消息数不对和跳动问题 ([f25deb9](https://review.byted.org/#/q/f25deb9)), closes [#1240](https://jira.bytedance.com/browse/LKI-1240)
* **message:** 本地推送不做归并，修复id推送重复问题 ([e875d8c](https://review.byted.org/#/q/e875d8c)), closes [#1230](https://jira.bytedance.com/browse/LKI-1230)
* **message:** 网络电话 ([f5cf8df](https://review.byted.org/#/q/f5cf8df)), closes [#1163](https://jira.bytedance.com/browse/LKI-1163)
* **message:** 解决开子线程过多导致手机崩溃问题 ([0f26592](https://review.byted.org/#/q/0f26592))
* **search:** 搜索过滤隐藏的消息 ([6a37d7b](https://review.byted.org/#/q/6a37d7b)), closes [#1221](https://jira.bytedance.com/browse/LKI-1221)


### Features

* **contact:** 群人数达1500时关闭加人入口 ([667a6d0](https://review.byted.org/#/q/667a6d0)), closes [#1217](https://jira.bytedance.com/browse/LKI-1217)
* **message:** isHidden的UrgentCell显示此消息已被删除 && 详情页循环删除导致内存中状态更新不及时的问题 && file撤回文案修复 ([183a4c2](https://review.byted.org/#/q/183a4c2))
* **message:** messageFileContent撤销逻辑补充 ([a29e9a9](https://review.byted.org/#/q/a29e9a9))
* **message:** Model增加isHidden字段，对应数据库调整 ([c8c6898](https://review.byted.org/#/q/c8c6898)), closes [#1245](https://jira.bytedance.com/browse/LKI-1245)
* **message:** 修复电话有可能无法挂起的BUG ([bfbc859](https://review.byted.org/#/q/bfbc859)), closes [#1163](https://jira.bytedance.com/browse/LKI-1163)
* **message:** 增加加密库 ([95181b1](https://review.byted.org/#/q/95181b1)), closes [#1229](https://jira.bytedance.com/browse/LKI-1229)
* **message:** 完成撤回消息，内容清除 ([6aea8ca](https://review.byted.org/#/q/6aea8ca)), closes [#1221](https://jira.bytedance.com/browse/LKI-1221)
* **message:** 屏蔽服务器搜索来的删除消息 ([a19a5d7](https://review.byted.org/#/q/a19a5d7)), closes [#1241](https://jira.bytedance.com/browse/LKI-1241)
* **message:** 拨打网络电话增加弹窗提示 ([7b809b5](https://review.byted.org/#/q/7b809b5)), closes [#1163](https://jira.bytedance.com/browse/LKI-1163)
* **message:** 提供消息资源，内容删除方法 ([2eb2881](https://review.byted.org/#/q/2eb2881)), closes [#1241](https://jira.bytedance.com/browse/LKI-1241) [#1247](https://jira.bytedance.com/browse/LKI-1247) [#1248](https://jira.bytedance.com/browse/LKI-1248)
* **message:** 撤回物理文件删除 ([95eabbb](https://review.byted.org/#/q/95eabbb)), closes [#1221](https://jira.bytedance.com/browse/LKI-1221)
* **web:** Bear H5需求 ([fc90bf7](https://review.byted.org/#/q/fc90bf7)), closes [#1225](https://jira.bytedance.com/browse/LKI-1225)



<a name="1.2.11"></a>
## 1.2.11 (2017-12-08)


### Bug Fixes

* **message:** audio小红点pack逻辑问题 ([2951557](https://review.byted.org/#/q/2951557)), closes [#1126](https://jira.bytedance.com/browse/LKI-1126)
* **message:** 优化图片在移动设备上的显示效果 ([1916824](https://review.byted.org/#/q/1916824)), closes [#801](https://jira.bytedance.com/browse/LKI-801)
* **message:** 修复上拉／下拉加载不出本地数据问题 ([3a7249c](https://review.byted.org/#/q/3a7249c)), closes [#1227](https://jira.bytedance.com/browse/LKI-1227)
* **message:** 在线PUSH不要进行自动合并、拉取消息判空 ([825489d](https://review.byted.org/#/q/825489d)), closes [#1213](https://jira.bytedance.com/browse/LKI-1213)
* **message:** 由于判定sid是否是数字的逻辑使用int32为进行转换，造成sid不能保存，导致管道拉 ([41a942e](https://review.byted.org/#/q/41a942e)), closes [#1218](https://jira.bytedance.com/browse/LKI-1218) [#1219](https://jira.bytedance.com/browse/LKI-1219)
* **message:** 语音本地通知时间格式不对 ([b420139](https://review.byted.org/#/q/b420139)), closes [#1222](https://jira.bytedance.com/browse/LKI-1222)
* **message:** 部分office文件无法打开 ([eac0e26](https://review.byted.org/#/q/eac0e26)), closes [#1226](https://jira.bytedance.com/browse/LKI-1226)
* **message:** 部分office文件无法打开/reactionview可能的闪退/失败图大小太小 ([d29f5dd](https://review.byted.org/#/q/d29f5dd)), closes [#1226](https://jira.bytedance.com/browse/LKI-1226)
* **urgent:** 防止反复收到PushUrgentAckRequest导致的提醒重复问题 ([c7f684d](https://review.byted.org/#/q/c7f684d)), closes [#1216](https://jira.bytedance.com/browse/LKI-1216)
* **web:** 头条链接打开后无法唤起头条App ([f0d561e](https://review.byted.org/#/q/f0d561e)), closes [#1223](https://jira.bytedance.com/browse/LKI-1223)


### Features

* **login:** 增加Shared Keychain的kSecAttrService属性设置 ([d309ade](https://review.byted.org/#/q/d309ade)), closes [#1160](https://jira.bytedance.com/browse/LKI-1160)
* **web:** 支持AppCenter和JsSDK打点逻辑 ([a1b2945](https://review.byted.org/#/q/a1b2945))



<a name="1.2.10"></a>
## 1.2.10 (2017-12-05)


### Bug Fixes

* **message:** 修复非首屏会话聊天页消息加载不出来的问题 ([f52a2d7](https://review.byted.org/#/q/f52a2d7)), closes [#1200](https://jira.bytedance.com/browse/LKI-1200)
* **message:** 由于服务器会发送非int的sid造成客户端使用不合法的sid拉取管子，产生问题 ([32dfac4](https://review.byted.org/#/q/32dfac4)), closes [#1157](https://jira.bytedance.com/browse/LKI-1157)
* **search:** 搜索本地不排序 ([201d607](https://review.byted.org/#/q/201d607)), closes [#1199](https://jira.bytedance.com/browse/LKI-1199)
* **search:** 搜索本地消息死锁闪退 ([de9a015](https://review.byted.org/#/q/de9a015)), closes [#1158](https://jira.bytedance.com/browse/LKI-1158)
* **web:** 解决头条圈点击二级页面没返回 ([336d241](https://review.byted.org/#/q/336d241)), closes [#1159](https://jira.bytedance.com/browse/LKI-1159)


### Features

* **login:** 支持Docs通过Shared Keychain获取Token ([307c53d](https://review.byted.org/#/q/307c53d)), closes [#1160](https://jira.bytedance.com/browse/LKI-1160)



<a name="1.2.9"></a>
## 1.2.9 (2017-12-01)


### Bug Fixes

* **component:** 修改BaseWebViewController中KVO崩溃 ([e9abed5](https://review.byted.org/#/q/e9abed5)), closes [#1033](https://jira.bytedance.com/browse/LKI-1033)
* **contact:** 尝试解决头像锯齿的问题, 切换头像的tos url跟Android 相同 ([54b4594](https://review.byted.org/#/q/54b4594)), closes [#1054](https://jira.bytedance.com/browse/LKI-1054)
* **login:** 多端登陆细节调整 ([df5dc2b](https://review.byted.org/#/q/df5dc2b)), closes [#1122](https://jira.bytedance.com/browse/LKI-1122)
* **message:** sticker上传，默认使用压缩过的图 ([c5600d9](https://review.byted.org/#/q/c5600d9)), closes [#1153](https://jira.bytedance.com/browse/LKI-1153)
* **message:** sticker产品走查若干问题修复，详见Jira 1153 ([c0f95eb](https://review.byted.org/#/q/c0f95eb)), closes [#1153](https://jira.bytedance.com/browse/LKI-1153)
* **message:** sticker默认使用原图 ([7c83f00](https://review.byted.org/#/q/7c83f00)), closes [#1153](https://jira.bytedance.com/browse/LKI-1153)
* **message:** 快速发消息，聊天中最后一条状态没有更新 ([4d52c29](https://review.byted.org/#/q/4d52c29)), closes [#1115](https://jira.bytedance.com/browse/LKI-1115)
* **message:** 旧会话只有一条最近的消息, 下拉后能拉出更多的消息 ([2a7e77a](https://review.byted.org/#/q/2a7e77a)), closes [#1145](https://jira.bytedance.com/browse/LKI-1145)
* **message:** 读消息更新时序不对，详情页语音播放没有动画，content增加对应protocol ([2ff34c7](https://review.byted.org/#/q/2ff34c7)), closes [#1144](https://jira.bytedance.com/browse/LKI-1144)
* **setting:** 设置页开关会互相干扰 ([c6421aa](https://review.byted.org/#/q/c6421aa)), closes [#1152](https://jira.bytedance.com/browse/LKI-1152)
* **web:** loading白屏问题修复 ([89fad99](https://review.byted.org/#/q/89fad99))
* **web:** 头条圈内容错位问题修复 ([ce0270b](https://review.byted.org/#/q/ce0270b)), closes [#1128](https://jira.bytedance.com/browse/LKI-1128)


### Features

* **contact:** 个人头像修改支持 push ([642bb6a](https://review.byted.org/#/q/642bb6a)), closes [#1132](https://jira.bytedance.com/browse/LKI-1132)
* **login:** 多端登录增加更新设备信息的接口 ([d82d928](https://review.byted.org/#/q/d82d928)), closes [#1154](https://jira.bytedance.com/browse/LKI-1154)
* **login:** 支持设备信息更新接口 ([9a2c51f](https://review.byted.org/#/q/9a2c51f)), closes [#1154](https://jira.bytedance.com/browse/LKI-1154)



<a name="1.2.9-beta4"></a>
## 1.2.9-beta4 (2017-11-30)


### Bug Fixes

* **chat:** 头像从缩略图替换成原图 ([607364c](https://review.byted.org/#/q/607364c)), closes [#1054](https://jira.bytedance.com/browse/LKI-1054)
* **chat:** 有一个chat的badge消不掉 ([293c0a0](https://review.byted.org/#/q/293c0a0)), closes [#1017](https://jira.bytedance.com/browse/LKI-1017)
* **message:** 优化消息文本截断策略,尽可能显示更多信息 ([a2d64d7](https://review.byted.org/#/q/a2d64d7)), closes [#1049](https://jira.bytedance.com/browse/LKI-1049)
* **message:** 增加首页错乱预防措施 ([bd8319f](https://review.byted.org/#/q/bd8319f)), closes [#1134](https://jira.bytedance.com/browse/LKI-1134)
* **message:** 我点赞应该排在第一位 ([a27230a](https://review.byted.org/#/q/a27230a)), closes [#1138](https://jira.bytedance.com/browse/LKI-1138)
* **web:** webview打开链接失败时，不将错误直接暴露给用户 ([f686a0e](https://review.byted.org/#/q/f686a0e)), closes [#1136](https://jira.bytedance.com/browse/LKI-1136)
* **web:** 修复cookie问题 && 头条圈问题 ([3c4c447](https://review.byted.org/#/q/3c4c447))


### Features

* **chat:** 群降噪 ([9d1f6e4](https://review.byted.org/#/q/9d1f6e4)), closes [#1027](https://jira.bytedance.com/browse/LKI-1027)
* **component:** 埋点5期，补充二 ([44ac7a9](https://review.byted.org/#/q/44ac7a9)), closes [#1141](https://jira.bytedance.com/browse/LKI-1141)
* **web:** webview初始进度0.1 ([6134197](https://review.byted.org/#/q/6134197)), closes [#1140](https://jira.bytedance.com/browse/LKI-1140)



<a name="1.2.9-beta3"></a>
## 1.2.9-beta3 (2017-11-29)


### Bug Fixes

* **chat:** 客服群进入的是其他人的 ([9d6e9d0](https://review.byted.org/#/q/9d6e9d0)), closes [#1111](https://jira.bytedance.com/browse/LKI-1111)
* **component:** iPhone X上查看大图时长图不能拖动 ([30f1d97](https://review.byted.org/#/q/30f1d97)), closes [#1098](https://jira.bytedance.com/browse/LKI-1098)
* **contact:** 离线 push 用户信息变化时启动强制更新用户信息 ([a9f3fa0](https://review.byted.org/#/q/a9f3fa0)), closes [#1132](https://jira.bytedance.com/browse/LKI-1132)
* **feed:** 解决卡顿问题 ([e9306c4](https://review.byted.org/#/q/e9306c4)), closes [#1120](https://jira.bytedance.com/browse/LKI-1120)
* **login:** 修复登陆时，设置参数存储不上的问题 ([6e600cb](https://review.byted.org/#/q/6e600cb)), closes [#740](https://jira.bytedance.com/browse/LKI-740)
* **login:** 被踢出，头像显示是之前用户的，电话是当前用户的 ([7eb9217](https://review.byted.org/#/q/7eb9217)), closes [#1127](https://jira.bytedance.com/browse/LKI-1127)
* **message:** 修复发送表情没打点 ([b72752f](https://review.byted.org/#/q/b72752f)), closes [#1106](https://jira.bytedance.com/browse/LKI-1106)
* **message:** 单聊点赞通知内容不对 ([008a32e](https://review.byted.org/#/q/008a32e)), closes [#1131](https://jira.bytedance.com/browse/LKI-1131)
* **message:** 增加DT模块日志输出 ([ffe150b](https://review.byted.org/#/q/ffe150b)), closes [#1129](https://jira.bytedance.com/browse/LKI-1129)
* **message:** 增加websocket断开连接时日志输入error信息 ([d760238](https://review.byted.org/#/q/d760238)), closes [#1129](https://jira.bytedance.com/browse/LKI-1129)
* **message:** 调整后台进入前台重试机制 ([471d5c9](https://review.byted.org/#/q/471d5c9)), closes [#1129](https://jira.bytedance.com/browse/LKI-1129)
* **thread:** Thread数据加载问题 ([55bc36d](https://review.byted.org/#/q/55bc36d)), closes [#1113](https://jira.bytedance.com/browse/LKI-1113)


### Features

* **contact:** push action 支持PushChatters ([b266d19](https://review.byted.org/#/q/b266d19)), closes [#1125](https://jira.bytedance.com/browse/LKI-1125)
* **login:** 增加SyncPnsToken函数中的日志打印 ([612cd13](https://review.byted.org/#/q/612cd13)), closes [#740](https://jira.bytedance.com/browse/LKI-740)



<a name="1.2.9-beta2"></a>
## 1.2.9-beta2 (2017-11-28)


### Bug Fixes

* **chat:** 避免一种pushToChat在前台被误触发的情况 ([6fbb668](https://review.byted.org/#/q/6fbb668)), closes [#1103](https://jira.bytedance.com/browse/LKI-1103)
* **message:** Reaction错乱、分享群不对、拉不到changelog ([471e9d4](https://review.byted.org/#/q/471e9d4)), closes [#1112](https://jira.bytedance.com/browse/LKI-1112)
* **message:** 修改Sticker不能上传原图的问题 ([6986c1a](https://review.byted.org/#/q/6986c1a)), closes [#1123](https://jira.bytedance.com/browse/LKI-1123)
* **message:** 修改表情管理页面产品走查的问题 ([7927c79](https://review.byted.org/#/q/7927c79)), closes [#1117](https://jira.bytedance.com/browse/LKI-1117)
* **message:** 点击远程push，进入回话，没有显示新消息数气泡 ([d2d405d](https://review.byted.org/#/q/d2d405d)), closes [#1114](https://jira.bytedance.com/browse/LKI-1114)
* **message:** 聊天最后一条消息通过异步加载 ([d473a7d](https://review.byted.org/#/q/d473a7d)), closes [#1124](https://jira.bytedance.com/browse/LKI-1124)
* **thread:** 详情页回复不出，fix modelaggregator/reactionapi ([52b92ba](https://review.byted.org/#/q/52b92ba)), closes [#1113](https://jira.bytedance.com/browse/LKI-1113)
* **urgent:** 我发的加急也会显示，没有过滤 ([cee6545](https://review.byted.org/#/q/cee6545)), closes [#1097](https://jira.bytedance.com/browse/LKI-1097)


### Features

* **login:** 处理多端登录登录时间的时区问题 ([1c65fbd](https://review.byted.org/#/q/1c65fbd)), closes [#740](https://jira.bytedance.com/browse/LKI-740)
* **login:** 添加被踢时马上返回登录界面的处理 ([1179a2d](https://review.byted.org/#/q/1179a2d)), closes [#740](https://jira.bytedance.com/browse/LKI-740)
* **login:** 自测完成多端登陆并进行bug修改，需求完成 ([b6b8788](https://review.byted.org/#/q/b6b8788)), closes [#740](https://jira.bytedance.com/browse/LKI-740)


### Performance Improvements

* **chat:** 同步消息卡顿 ([7d4e5be](https://review.byted.org/#/q/7d4e5be)), closes [#1121](https://jira.bytedance.com/browse/LKI-1121)



<a name="1.2.9-beta1"></a>
## 1.2.9-beta1 (2017-11-27)


### Bug Fixes

* **chat:** 修复chat updateLastMsg时user没有的问题 ([5ce6970](https://review.byted.org/#/q/5ce6970)), closes [#1076](https://jira.bytedance.com/browse/LKI-1076)
* **chat:** 修正某些情况下可能push无法触发直达会话的问题 ([2928860](https://review.byted.org/#/q/2928860)), closes [#1103](https://jira.bytedance.com/browse/LKI-1103)
* **chat:** 踢出会话push对接没有做filter处理 ([7514944](https://review.byted.org/#/q/7514944)), closes [#1084](https://jira.bytedance.com/browse/LKI-1084)
* **contact:** 修复无法查看"我的群组"里面所有群的问题 ([206b672](https://review.byted.org/#/q/206b672)), closes [#1100](https://jira.bytedance.com/browse/LKI-1100)
* **message:** 修复点击@用户进不了名片页和拨打电话消息显示错误的问题 ([413e28f](https://review.byted.org/#/q/413e28f)), closes [#1086](https://jira.bytedance.com/browse/LKI-1086)
* **message:** 去掉sticker消息详情页的加急选项 ([308a8a4](https://review.byted.org/#/q/308a8a4)), closes [#1107](https://jira.bytedance.com/browse/LKI-1107)
* **message:** 发消息已读未读不对的问题 ([c170e59](https://review.byted.org/#/q/c170e59)), closes [#1095](https://jira.bytedance.com/browse/LKI-1095)
* **message:** 帖子的RootMessage 无法聚合造成打开帖子详情，显示异常。 ([7d89ec7](https://review.byted.org/#/q/7d89ec7)), closes [#1083](https://jira.bytedance.com/browse/LKI-1083)
* **message:** 当发送图片成功的时候，图片气泡会有一次闪动 ([00a12bb](https://review.byted.org/#/q/00a12bb)), closes [#1092](https://jira.bytedance.com/browse/LKI-1092)
* **message:** 当客户端进入后台后，如果遇到网络中断且多次重试无法恢复的时候，再次打开进入前台会显示未连接 ([84075d4](https://review.byted.org/#/q/84075d4)), closes [#1099](https://jira.bytedance.com/browse/LKI-1099) [#1080](https://jira.bytedance.com/browse/LKI-1080)
* **message:** 群分享消息无法发送 ([2d48219](https://review.byted.org/#/q/2d48219)), closes [#1088](https://jira.bytedance.com/browse/LKI-1088)
* **message:** 菜单选择栏功能优化 ([a9c1763](https://review.byted.org/#/q/a9c1763)), closes [#1071](https://jira.bytedance.com/browse/LKI-1071)
* **message:** 补全sticker通知显示图片逻辑 ([6f0070b](https://review.byted.org/#/q/6f0070b)), closes [#1109](https://jira.bytedance.com/browse/LKI-1109)
* **message:** 解决图片消息发送中时，消息中的图片气泡始终显示成灰色。 ([b5a04e8](https://review.byted.org/#/q/b5a04e8)), closes [#1081](https://jira.bytedance.com/browse/LKI-1081)
* **message:** 转发消息没有显示用户名，排序不对 ([9ee87b4](https://review.byted.org/#/q/9ee87b4)), closes [#1104](https://jira.bytedance.com/browse/LKI-1104)
* **urgent:** 我发的加急也会显示，没有过滤 ([398b8dc](https://review.byted.org/#/q/398b8dc)), closes [#1097](https://jira.bytedance.com/browse/LKI-1097)
* **web:** 在WKWebView的setCookie方法上打日志，记录不同机型的不同cookie文件情况 ([8789453](https://review.byted.org/#/q/8789453)), closes [#1010](https://jira.bytedance.com/browse/LKI-1010)
* **web:** 解决iOS WKWebview Cookie同步问题 ([af11da8](https://review.byted.org/#/q/af11da8)), closes [#1010](https://jira.bytedance.com/browse/LKI-1010)


### Features

* **component:** 客户端埋点5期 ([bd07b5c](https://review.byted.org/#/q/bd07b5c)), closes [#1079](https://jira.bytedance.com/browse/LKI-1079)
* **contact:** 个别人支持通讯录组织架构处显示总人数 ([f0523d4](https://review.byted.org/#/q/f0523d4)), closes [#1082](https://jira.bytedance.com/browse/LKI-1082)
* **feed:** 发消息移动到收件箱 ([55dc2a8](https://review.byted.org/#/q/55dc2a8)), closes [#1094](https://jira.bytedance.com/browse/LKI-1094)
* **login:** switch控件提换，多端登陆实现细节补充 ([d91add3](https://review.byted.org/#/q/d91add3)), closes [#740](https://jira.bytedance.com/browse/LKI-740)
* **login:** 基本完成多端登陆相关逻辑 ([25e5d77](https://review.byted.org/#/q/25e5d77)), closes [#740](https://jira.bytedance.com/browse/LKI-740)
* **login:** 支持海外用户登录 ([a7a7bc5](https://review.byted.org/#/q/a7a7bc5)), closes [#1021](https://jira.bytedance.com/browse/LKI-1021) [#1052](https://jira.bytedance.com/browse/LKI-1052)
* **message:** sticker init ([e8ed52a](https://review.byted.org/#/q/e8ed52a)), closes [#915](https://jira.bytedance.com/browse/LKI-915)
* **message:** sticker 部分兼容 message detail ([531da2e](https://review.byted.org/#/q/531da2e)), closes [#1085](https://jira.bytedance.com/browse/LKI-1085)
* **message:** 上传表情到服务器 ([666df5a](https://review.byted.org/#/q/666df5a)), closes [#915](https://jira.bytedance.com/browse/LKI-915)
* **message:** 优化 sticker manager 重载逻辑 ([db4c7dd](https://review.byted.org/#/q/db4c7dd)), closes [#1101](https://jira.bytedance.com/browse/LKI-1101)
* **message:** 传文件时的ICON补充 ([72fcff9](https://review.byted.org/#/q/72fcff9)), closes [#1073](https://jira.bytedance.com/browse/LKI-1073)
* **message:** 修正上传日志名称 ([d1fda1c](https://review.byted.org/#/q/d1fda1c)), closes [#1070](https://jira.bytedance.com/browse/LKI-1070)
* **message:** 修正表情数据格式 ([d6452ae](https://review.byted.org/#/q/d6452ae)), closes [#1062](https://jira.bytedance.com/browse/LKI-1062)
* **message:** 完善 sticker 上传规则 ([def6416](https://review.byted.org/#/q/def6416)), closes [#1053](https://jira.bytedance.com/browse/LKI-1053)
* **message:** 富文本优化 ([d2dda7a](https://review.byted.org/#/q/d2dda7a)), closes [#990](https://jira.bytedance.com/browse/LKI-990)
* **message:** 对话中，长按表情菜单中，增加一个"添加到表情"选项 ([128b828](https://review.byted.org/#/q/128b828)), closes [#1044](https://jira.bytedance.com/browse/LKI-1044)
* **message:** 添加sticker本地存储 ([19fdfd0](https://review.byted.org/#/q/19fdfd0)), closes [#1053](https://jira.bytedance.com/browse/LKI-1053)
* **message:** 添加sticker类型的cell ([1af8241](https://review.byted.org/#/q/1af8241)), closes [#1044](https://jira.bytedance.com/browse/LKI-1044)
* **message:** 添加发送 sticker 的逻辑 ([8a9d808](https://review.byted.org/#/q/8a9d808)), closes [#1045](https://jira.bytedance.com/browse/LKI-1045)
* **message:** 补充埋点（自定义表情相关） ([d345240](https://review.byted.org/#/q/d345240)), closes [#1106](https://jira.bytedance.com/browse/LKI-1106)
* **message:** 表情管理，置顶，删除 ([5c1b5a6](https://review.byted.org/#/q/5c1b5a6)), closes [#1043](https://jira.bytedance.com/browse/LKI-1043)
* **message:** 表情管理功能 ([a2169e4](https://review.byted.org/#/q/a2169e4)), closes [#1043](https://jira.bytedance.com/browse/LKI-1043)


### Reverts

* **message:** 修复合并问题 ([2de2881](https://review.byted.org/#/q/2de2881))



<a name="1.2.8"></a>
## 1.2.8 (2017-11-23)


### Bug Fixes

* **chat:** 会话设置 tableview 顶部高度错误 ([41456d2](https://review.byted.org/#/q/41456d2)), closes [#1057](https://jira.bytedance.com/browse/LKI-1057)
* **contact:** 优化个人页显示细节 ([4fd2c6a](https://review.byted.org/#/q/4fd2c6a)), closes [#1023](https://jira.bytedance.com/browse/LKI-1023)
* **message:** ChatViewController.voiceManager.getter导致的crash ([78e2bd2](https://review.byted.org/#/q/78e2bd2)), closes [#1058](https://jira.bytedance.com/browse/LKI-1058)
* **message:** KeyboardPanel.setContent 的crash ([dacc4c1](https://review.byted.org/#/q/dacc4c1)), closes [#1059](https://jira.bytedance.com/browse/LKI-1059)
* **message:** ReactionTag.model.didset导致的crash ([5841cee](https://review.byted.org/#/q/5841cee)), closes [#1058](https://jira.bytedance.com/browse/LKI-1058)
* **message:** 修复图片加载失败BUG ([0267316](https://review.byted.org/#/q/0267316)), closes [#1061](https://jira.bytedance.com/browse/LKI-1061)
* **message:** 解决键盘crash问题修复回滚, 解决方案不可用. ([124d997](https://review.byted.org/#/q/124d997)), closes [#1059](https://jira.bytedance.com/browse/LKI-1059)
* **message:** 适配iPhoneX ([4e6f65d](https://review.byted.org/#/q/4e6f65d)), closes [#1068](https://jira.bytedance.com/browse/LKI-1068)
* **message:** 适配X ([646f0e3](https://review.byted.org/#/q/646f0e3)), closes [#1068](https://jira.bytedance.com/browse/LKI-1068)


### Features

* **component:** 【对话Lark团队】文字改为「专属Lark客服」（左侧抽屉&我的2处） ([50476b8](https://review.byted.org/#/q/50476b8)), closes [#1046](https://jira.bytedance.com/browse/LKI-1046)
* **contact:** 千人群设置优化,名片页增加城市字段 ([ac344c6](https://review.byted.org/#/q/ac344c6)), closes [#1038](https://jira.bytedance.com/browse/LKI-1038)
* **message:** 群分享添加新的错误类型 ([eb88117](https://review.byted.org/#/q/eb88117)), closes [#1056](https://jira.bytedance.com/browse/LKI-1056)
* **setting:** 系统设置里可以清除缓存 ([3ac09af](https://review.byted.org/#/q/3ac09af)), closes [#1048](https://jira.bytedance.com/browse/LKI-1048)



<a name="1.2.7"></a>
## 1.2.7 (2017-11-20)


### Bug Fixes

* **chat:** 优化会话设置和消息文本截断 ([8c109a3](https://review.byted.org/#/q/8c109a3)), closes [#1023](https://jira.bytedance.com/browse/LKI-1023)
* **chat:** 机器人不显示打电话icon ([e8e7a98](https://review.byted.org/#/q/e8e7a98)), closes [#1023](https://jira.bytedance.com/browse/LKI-1023)
* **search:** 解决搜索界面结果与搜索内容不对应的问题 ([fa1cb8d](https://review.byted.org/#/q/fa1cb8d)), closes [#1047](https://jira.bytedance.com/browse/LKI-1047)
* **web:** 修复切换用户未清理cookie的问题 ([9bd6cec](https://review.byted.org/#/q/9bd6cec)), closes [#1051](https://jira.bytedance.com/browse/LKI-1051)



<a name="1.2.7-beta2"></a>
## 1.2.7-beta2 (2017-11-17)


### Features

* **contact:** 修改组织显示, 增加会话设置 ([fa25896](https://review.byted.org/#/q/fa25896)), closes [#1023](https://jira.bytedance.com/browse/LKI-1023)



<a name="1.2.7-beta1"></a>
## 1.2.7-beta1 (2017-11-17)


### Bug Fixes

* **chat:** 发起群聊，搜索联系人，可能出现重复的联系人 ([1057850](https://review.byted.org/#/q/1057850)), closes [#1003](https://jira.bytedance.com/browse/LKI-1003)
* **chat:** 转发消息，当选择一个只有一个人的chat，再搜索这个user的时候，还可以选这个user ([b767bd7](https://review.byted.org/#/q/b767bd7)), closes [#1004](https://jira.bytedance.com/browse/LKI-1004)
* **component:** 拉取beta更新信息失败 ([39118ad](https://review.byted.org/#/q/39118ad)), closes [#1042](https://jira.bytedance.com/browse/LKI-1042)
* **component:** 点击@人可能导致越界问题修复 ([06bb697](https://review.byted.org/#/q/06bb697)), closes [#984](https://jira.bytedance.com/browse/LKI-984)
* **component:** 解决webview bear域名的URL打不开 ([61ab35f](https://review.byted.org/#/q/61ab35f)), closes [#967](https://jira.bytedance.com/browse/LKI-967)
* **component:** 解决两处crash ([45ea42a](https://review.byted.org/#/q/45ea42a)), closes [#1033](https://jira.bytedance.com/browse/LKI-1033)
* **contact:** 使用namepy字段代替namepinyin ([e26c70a](https://review.byted.org/#/q/e26c70a)), closes [#1006](https://jira.bytedance.com/browse/LKI-1006) [#1009](https://jira.bytedance.com/browse/LKI-1009)
* **message:** ChatViewController onExit() crash修复 ([dca614d](https://review.byted.org/#/q/dca614d)), closes [#894](https://jira.bytedance.com/browse/LKI-894)
* **message:** messagePacker 多次leave没能拦截的bug ([85264db](https://review.byted.org/#/q/85264db)), closes [#1026](https://jira.bytedance.com/browse/LKI-1026)
* **message:** pullDown导致的crash ([0956526](https://review.byted.org/#/q/0956526)), closes [#1002](https://jira.bytedance.com/browse/LKI-1002)
* **message:** 修复贴子图片未加宽高BUG ([9adde4c](https://review.byted.org/#/q/9adde4c)), closes [#766](https://jira.bytedance.com/browse/LKI-766)
* **message:** 修复重构中残留的todo ([0a7a471](https://review.byted.org/#/q/0a7a471)), closes [#998](https://jira.bytedance.com/browse/LKI-998)
* **message:** 修改撤回消息文案错误 ([ecba818](https://review.byted.org/#/q/ecba818)), closes [#439](https://jira.bytedance.com/browse/LKI-439)
* **message:** 进入后台后新来的消息不发送已读 ([f6c5730](https://review.byted.org/#/q/f6c5730)), closes [#1040](https://jira.bytedance.com/browse/LKI-1040)
* **web:** iOS 9打开头条圈只有第一次有效，第二次无法打开 ([9e71d3d](https://review.byted.org/#/q/9e71d3d)), closes [#966](https://jira.bytedance.com/browse/LKI-966)
* **web:** wiki/docs的cookie遇到的401问题 ([a9b215c](https://review.byted.org/#/q/a9b215c)), closes [#1037](https://jira.bytedance.com/browse/LKI-1037)
* **web:** 解决session cookie没有写入.bytedance.net导致的问题 ([9b1c8f5](https://review.byted.org/#/q/9b1c8f5)), closes [#1010](https://jira.bytedance.com/browse/LKI-1010)


### Features

* **chat:** 添加附件上传组件 ([75e723e](https://review.byted.org/#/q/75e723e)), closes [#766](https://jira.bytedance.com/browse/LKI-766)
* **message:** thread详情页增加水印 ([c68fbde](https://review.byted.org/#/q/c68fbde)), closes [#1013](https://jira.bytedance.com/browse/LKI-1013)
* **message:** 对接服务器PushSID接口，解决数据包截断后，无法通过推送送达问题 ([f68df96](https://review.byted.org/#/q/f68df96)), closes [#961](https://jira.bytedance.com/browse/LKI-961)


### Performance Improvements

* **login:** 提升二维码扫描识别率 ([d7b2097](https://review.byted.org/#/q/d7b2097)), closes [#1012](https://jira.bytedance.com/browse/LKI-1012)



<a name="1.2.6"></a>
## 1.2.6 (2017-11-03)


### Bug Fixes

* **chat:** 关闭通知的群变成了开启通知 ([6c2682a](https://review.byted.org/#/q/6c2682a)), closes [#948](https://jira.bytedance.com/browse/LKI-948)
* **chat:** 更改chatsetting的userdefault字段 ([18ec54b](https://review.byted.org/#/q/18ec54b)), closes [#948](https://jira.bytedance.com/browse/LKI-948)
* **component:** webview可能出现标题过长遮挡按钮的问题(ios10) ([8573f86](https://review.byted.org/#/q/8573f86)), closes [#951](https://jira.bytedance.com/browse/LKI-951)
* **component:** 修正表情被拉伸问题 ([13c0211](https://review.byted.org/#/q/13c0211)), closes [#940](https://jira.bytedance.com/browse/LKI-940)
* **component:** 修正顶部title没有的问题 ([122c098](https://review.byted.org/#/q/122c098)), closes [#954](https://jira.bytedance.com/browse/LKI-954)
* **component:** 彻底解决LKLabel查看全部出现不合理的问题 ([65abe9d](https://review.byted.org/#/q/65abe9d)), closes [#956](https://jira.bytedance.com/browse/LKI-956)
* **component:** 支持网页链接分享转发 ([a2092ee](https://review.byted.org/#/q/a2092ee)), closes [#914](https://jira.bytedance.com/browse/LKI-914)
* **component:** 解决LKLabel查看全部出现不合理的问题 ([c6e3019](https://review.byted.org/#/q/c6e3019)), closes [#956](https://jira.bytedance.com/browse/LKI-956)
* **component:** 解决webview导致的崩溃问题 ([6f01bf0](https://review.byted.org/#/q/6f01bf0)), closes [#946](https://jira.bytedance.com/browse/LKI-946)
* **component:** 访问特色功能介绍，页面异常，账号登出，修改文档地址 ([1f11a45](https://review.byted.org/#/q/1f11a45)), closes [#933](https://jira.bytedance.com/browse/LKI-933) [#945](https://jira.bytedance.com/browse/LKI-945)
* **contact:** 群名片页：群名称下面人数，蒙版上显示的人数修改 ([780fd50](https://review.byted.org/#/q/780fd50)), closes [#943](https://jira.bytedance.com/browse/LKI-943)
* **message:** 登陆改成POST ([f66ab26](https://review.byted.org/#/q/f66ab26)), closes [#963](https://jira.bytedance.com/browse/LKI-963)
* **message:** 群分享消息发送到当前群会导致badge消除不掉 ([c6eaa7e](https://review.byted.org/#/q/c6eaa7e)), closes [#929](https://jira.bytedance.com/browse/LKI-929)
* **setting:** 修改当前版本检测机制 ([5161457](https://review.byted.org/#/q/5161457)), closes [#952](https://jira.bytedance.com/browse/LKI-952)
* **thread:** 详情页表情丢失 ([540da0d](https://review.byted.org/#/q/540da0d)), closes [#964](https://jira.bytedance.com/browse/LKI-964)
* **web:** webview返回页面空白和导航颜色不对 ([0d06c74](https://review.byted.org/#/q/0d06c74)), closes [#957](https://jira.bytedance.com/browse/LKI-957) [#958](https://jira.bytedance.com/browse/LKI-958)


### Features

* **chat:** Emoji图片资源使用独立bundle ([1a62890](https://review.byted.org/#/q/1a62890)), closes [#955](https://jira.bytedance.com/browse/LKI-955)
* **chat:** 添加新表情[OK][加油][爱心] ([7044ede](https://review.byted.org/#/q/7044ede)), closes [#955](https://jira.bytedance.com/browse/LKI-955)
* **web:** webview增加获取cookie接口 ([734cd99](https://review.byted.org/#/q/734cd99)), closes [#962](https://jira.bytedance.com/browse/LKI-962)



<a name="1.2.5"></a>
## 1.2.5 (2017-10-31)


### Bug Fixes

* **chat:** 修复由于table单例引起的崩溃 ([54a1ca2](https://review.byted.org/#/q/54a1ca2)), closes [#891](https://jira.bytedance.com/browse/LKI-891)
* **chat:** 修复贴子无法发送BUG ([ed9421a](https://review.byted.org/#/q/ed9421a)), closes [#939](https://jira.bytedance.com/browse/LKI-939)
* **component:** LKTextLayoutEngineImpl的preferMaxWidth逻辑bug修复 ([90d8ec3](https://review.byted.org/#/q/90d8ec3)), closes [#928](https://jira.bytedance.com/browse/LKI-928)
* **component:** 修复以下问题： ([43bb287](https://review.byted.org/#/q/43bb287)), closes [#938](https://jira.bytedance.com/browse/LKI-938) [#926](https://jira.bytedance.com/browse/LKI-926)
* **component:** 修复以下问题： ([0555c49](https://review.byted.org/#/q/0555c49)), closes [#827](https://jira.bytedance.com/browse/LKI-827)
* **component:** 修复路由跳转处理挂起页面BUG ([8474724](https://review.byted.org/#/q/8474724)), closes [#894](https://jira.bytedance.com/browse/LKI-894)
* **component:** 迁移到Https接口 ([89ba207](https://review.byted.org/#/q/89ba207)), closes [#930](https://jira.bytedance.com/browse/LKI-930)
* **contact:** beta8 -> beta9 本地存储的名片会显示不在同一企业的错误 ([1e9faa0](https://review.byted.org/#/q/1e9faa0)), closes [#932](https://jira.bytedance.com/browse/LKI-932)
* **contact:** UI修改：群分享按钮外露出来 ([2115f14](https://review.byted.org/#/q/2115f14)), closes [#942](https://jira.bytedance.com/browse/LKI-942)
* **contact:** 修复 beta8 -> beta9 本地存储的名片会显示不在同一企业和电话/消息 icon 不显示的错误 ([6275bf7](https://review.byted.org/#/q/6275bf7)), closes [#932](https://jira.bytedance.com/browse/LKI-932)
* **contact:** 修复群名字过长把title顶出去的问题 ([acf989a](https://review.byted.org/#/q/acf989a)), closes [#932](https://jira.bytedance.com/browse/LKI-932)
* **contact:** 名片页自己去掉电话按钮 ([9585fbb](https://review.byted.org/#/q/9585fbb)), closes [#942](https://jira.bytedance.com/browse/LKI-942)
* **message:** push进入会话逻辑调整 ([b14b0e6](https://review.byted.org/#/q/b14b0e6)), closes [#922](https://jira.bytedance.com/browse/LKI-922)
* **message:** 修复MessageReadStatusViewController里swift_unknownUnownedTakeStrong的Crash ([9f18e9d](https://review.byted.org/#/q/9f18e9d)), closes [#927](https://jira.bytedance.com/browse/LKI-927)
* **message:** 加载控件,加载不出更多数据 ([2058289](https://review.byted.org/#/q/2058289)), closes [#941](https://jira.bytedance.com/browse/LKI-941)
* **message:** 点击查“看更更多”会push两次 ([67345ea](https://review.byted.org/#/q/67345ea)), closes [#827](https://jira.bytedance.com/browse/LKI-827)
* **message:** 群分享失效后，存库 ([01b139c](https://review.byted.org/#/q/01b139c)), closes [#920](https://jira.bytedance.com/browse/LKI-920)
* **message:** 群分享失效状态 卡片cell和名片详情页同步更新 ([f07c483](https://review.byted.org/#/q/f07c483)), closes [#920](https://jira.bytedance.com/browse/LKI-920)
* **message:** 详情页加入对离职员工处理 ([c4cf29b](https://review.byted.org/#/q/c4cf29b)), closes [#875](https://jira.bytedance.com/browse/LKI-875)
* **message:** 转发消息会导致badge消除不掉 ([3dcf4cc](https://review.byted.org/#/q/3dcf4cc)), closes [#929](https://jira.bytedance.com/browse/LKI-929)
* **message:** 转发消息会导致badge消除不掉 ([170b0e8](https://review.byted.org/#/q/170b0e8)), closes [#929](https://jira.bytedance.com/browse/LKI-929)
* **search:** 修改搜索历史列表cell布局 ([5772eb7](https://review.byted.org/#/q/5772eb7)), closes [#937](https://jira.bytedance.com/browse/LKI-937)


### Features

* **chat:** 头条圈支持单击刷新 ([606894b](https://review.byted.org/#/q/606894b)), closes [#936](https://jira.bytedance.com/browse/LKI-936)
* **chat:** 对接新pullChatsByIds，改被踢出群提示方式 ([3a26b50](https://review.byted.org/#/q/3a26b50)), closes [#935](https://jira.bytedance.com/browse/LKI-935)
* **component:** 添加新的服务器Http自定义错误码 ([a2cfe6c](https://review.byted.org/#/q/a2cfe6c)), closes [#931](https://jira.bytedance.com/browse/LKI-931)



<a name="1.2.5-beta9"></a>
## 1.2.5-beta9 (2017-10-30)


### Bug Fixes

* **chat:** webview发图支持原图 ([c15af74](https://review.byted.org/#/q/c15af74)), closes [#921](https://jira.bytedance.com/browse/LKI-921)
* **chat:** 双击头条圈tab闪退 ([affbdb0](https://review.byted.org/#/q/affbdb0)), closes [#925](https://jira.bytedance.com/browse/LKI-925)
* **component:** ReactionTag因为ReactionModel userNames userIds不配对导致crash的问题 ([5317c5e](https://review.byted.org/#/q/5317c5e)), closes [#924](https://jira.bytedance.com/browse/LKI-924)
* **component:** ReactionView上面空行的问题以及reaction排序不对的问题 ([48c1f9b](https://review.byted.org/#/q/48c1f9b)), closes [#918](https://jira.bytedance.com/browse/LKI-918)
* **component:** 修复LKTextLayoutEngine某些字符导致descent计算偏差的问题 ([c2c71cb](https://review.byted.org/#/q/c2c71cb)), closes [#917](https://jira.bytedance.com/browse/LKI-917)
* **component:** 解决图片快速选择器与预览组件图片不对应的问题 ([a38795f](https://review.byted.org/#/q/a38795f)), closes [#919](https://jira.bytedance.com/browse/LKI-919)
* **contact:**  个人名片：「不同组织」「不同组织-已离职」的卡片显示不同信息 ([373139e](https://review.byted.org/#/q/373139e)), closes [#906](https://jira.bytedance.com/browse/LKI-906)
* **contact:** 分享进群卡片页, 群头像增加点击事件 ([6ce2ab3](https://review.byted.org/#/q/6ce2ab3)), closes [#923](https://jira.bytedance.com/browse/LKI-923)
* **message:** 从push点击消息进入加载的消息数量很少 ([54de9e2](https://review.byted.org/#/q/54de9e2)), closes [#922](https://jira.bytedance.com/browse/LKI-922)
* **message:** 失效的群分享卡片点击顶部可以进入群卡片页 ([070bd8c](https://review.byted.org/#/q/070bd8c)), closes [#920](https://jira.bytedance.com/browse/LKI-920)
* **message:** 群分享加入页面对接错误码 ([9da301f](https://review.byted.org/#/q/9da301f)), closes [#911](https://jira.bytedance.com/browse/LKI-911)
* **message:** 群分享对接错误码 ([dcd5112](https://review.byted.org/#/q/dcd5112)), closes [#911](https://jira.bytedance.com/browse/LKI-911)


### Features

* **component:** 添加 Server Error Code ([bdf7c7d](https://review.byted.org/#/q/bdf7c7d)), closes [#911](https://jira.bytedance.com/browse/LKI-911)



<a name="1.2.5-beta8"></a>
## 1.2.5-beta8 (2017-10-30)


### Bug Fixes

* **chat:** 修复每次进会话都会出现加载蒙版的问题 ([e841d56](https://review.byted.org/#/q/e841d56)), closes [#892](https://jira.bytedance.com/browse/LKI-892)
* **component:** BaseWebViewController解决键盘弹出消失导致webView innerHeight不对的问题 ([c77edc1](https://review.byted.org/#/q/c77edc1)), closes [#908](https://jira.bytedance.com/browse/LKI-908)
* **component:** icloud resizeMode参数由exact调整为fast ([61d8147](https://review.byted.org/#/q/61d8147)), closes [#912](https://jira.bytedance.com/browse/LKI-912)
* **component:** 修正群分享键盘遮挡计算错误 ([e155d68](https://review.byted.org/#/q/e155d68)), closes [#898](https://jira.bytedance.com/browse/LKI-898)
* **component:** 分享群名片界面键盘遮挡问题 ([307b0dc](https://review.byted.org/#/q/307b0dc)), closes [#898](https://jira.bytedance.com/browse/LKI-898)
* **component:** 群分享名片转发时文字布局超出范围 ([8c495aa](https://review.byted.org/#/q/8c495aa)), closes [#886](https://jira.bytedance.com/browse/LKI-886)
* **message:** 会话页面, 滚动数组越界 ([cf7f2dd](https://review.byted.org/#/q/cf7f2dd)), closes [#888](https://jira.bytedance.com/browse/LKI-888)
* **message:** 修复删除表情崩溃 ([14c57cd](https://review.byted.org/#/q/14c57cd)), closes [#890](https://jira.bytedance.com/browse/LKI-890)
* **message:** 修复群分享卡片的reaction处理没有在固定宽度内折行的问题 ([53410a5](https://review.byted.org/#/q/53410a5)), closes [#897](https://jira.bytedance.com/browse/LKI-897)
* **message:** 单聊会话界面处理离职员工，屏蔽电话，创建群，键盘输入和reaction功能 ([50ba12f](https://review.byted.org/#/q/50ba12f)), closes [#875](https://jira.bytedance.com/browse/LKI-875)
* **message:** 单聊建群cellbug, 文本cell文字突出 ([5c89891](https://review.byted.org/#/q/5c89891)), closes [#904](https://jira.bytedance.com/browse/LKI-904)
* **message:** 单聊建群同步消息时，若该单聊中包含群卡片，点击确定App会崩溃 ([6a0fa11](https://review.byted.org/#/q/6a0fa11)), closes [#904](https://jira.bytedance.com/browse/LKI-904)
* **message:** 失效的卡片不能进入群名片 ([cd837ee](https://review.byted.org/#/q/cd837ee)), closes [#899](https://jira.bytedance.com/browse/LKI-899)
* **message:** 消息页帖子里的at点击没有进入personal card ([ecb4b0e](https://review.byted.org/#/q/ecb4b0e)), closes [#887](https://jira.bytedance.com/browse/LKI-887)
* **message:** 点击回复图片导致列表刷新跳动 ([d3942e0](https://review.byted.org/#/q/d3942e0)), closes [#903](https://jira.bytedance.com/browse/LKI-903)
* **message:** 群分享卡片得分割线和reaction分割线一致 ([49d8bcb](https://review.byted.org/#/q/49d8bcb)), closes [#901](https://jira.bytedance.com/browse/LKI-901)
* **message:** 补全未知消息的处理 ([0029157](https://review.byted.org/#/q/0029157)), closes [#885](https://jira.bytedance.com/browse/LKI-885)
* **message:** 调整消息正文中自动换行策略为byWordWrapping ([f52a4c3](https://review.byted.org/#/q/f52a4c3)), closes [#800](https://jira.bytedance.com/browse/LKI-800)
* **setting:** 升级提示后, 自动退到后台, 便于升级安装 app ([fd70bbd](https://review.byted.org/#/q/fd70bbd)), closes [#907](https://jira.bytedance.com/browse/LKI-907)


### Features

* **component:** 完善挂起组件 ([7794494](https://review.byted.org/#/q/7794494)), closes [#905](https://jira.bytedance.com/browse/LKI-905)
* **message:** 修复输入框跳转BUG ([5e4a4b2](https://review.byted.org/#/q/5e4a4b2)), closes [#896](https://jira.bytedance.com/browse/LKI-896)
* **message:** 贴子图片可以使用原图 ([0222423](https://review.byted.org/#/q/0222423)), closes [#895](https://jira.bytedance.com/browse/LKI-895)
* **message:** 转发消息到另一个有badge的群，badge数加1，自己读过全部消息之后，消除所有badge ([6c1c08e](https://review.byted.org/#/q/6c1c08e)), closes [#882](https://jira.bytedance.com/browse/LKI-882)



<a name="1.2.5-beta7"></a>
## 1.2.5-beta7 (2017-10-27)


### Bug Fixes

* **contact:** 解决适配出现在 iOS11 上圆角切不掉的问题 ([f624fb4](https://review.byted.org/#/q/f624fb4)), closes [#884](https://jira.bytedance.com/browse/LKI-884)
* **message:** 群分享消息转发时没有正确换行, 修复创建单聊没有在主线程的闪退 ([0761f5d](https://review.byted.org/#/q/0761f5d)), closes [#883](https://jira.bytedance.com/browse/LKI-883)



<a name="1.2.5-beta6"></a>
## 1.2.5-beta6 (2017-10-27)


### Bug Fixes

* **component:** 解决ReactionView 动画会被refresh cell冲掉的问题 ([fb06df5](https://review.byted.org/#/q/fb06df5)), closes [#879](https://jira.bytedance.com/browse/LKI-879)
* **contact:** 名片页不同系统会导致圆角缺失 ([d9ca44f](https://review.byted.org/#/q/d9ca44f)), closes [#881](https://jira.bytedance.com/browse/LKI-881)
* **message:** UI微调 ([f51ecea](https://review.byted.org/#/q/f51ecea)), closes [#873](https://jira.bytedance.com/browse/LKI-873)
* **message:** 群分享直角卡片被覆盖 ([47b0188](https://review.byted.org/#/q/47b0188)), closes [#880](https://jira.bytedance.com/browse/LKI-880)
* **message:** 解决发送消息时，messages更新不正确的问题 ([f637f09](https://review.byted.org/#/q/f637f09)), closes [#874](https://jira.bytedance.com/browse/LKI-874)


### Features

* **chat:** 优化push直达会话跳转策略 ([6bb33b2](https://review.byted.org/#/q/6bb33b2)), closes [#876](https://jira.bytedance.com/browse/LKI-876)
* **chat:** 分享群消息 ([fbd4a02](https://review.byted.org/#/q/fbd4a02)), closes [#871](https://jira.bytedance.com/browse/LKI-871) [#843](https://jira.bytedance.com/browse/LKI-843)
* **chat:** 完成未加入的群名片页 ([f93d5ae](https://review.byted.org/#/q/f93d5ae)), closes [#863](https://jira.bytedance.com/browse/LKI-863)
* **chat:** 添加发送 share chat message功能 ([61ac8e4](https://review.byted.org/#/q/61ac8e4)), closes [#843](https://jira.bytedance.com/browse/LKI-843)
* **chat:** 调整share接口, 处理joinchat的返回结果 ([d5f05bb](https://review.byted.org/#/q/d5f05bb)), closes [#877](https://jira.bytedance.com/browse/LKI-877) [#843](https://jira.bytedance.com/browse/LKI-843)
* **component:** ReactionView支持新需求 ([55adbf8](https://review.byted.org/#/q/55adbf8)), closes [#812](https://jira.bytedance.com/browse/LKI-812)
* **message:** thread回复消息撤回后，还需要在会话窗口里显示根消息，同PC ([0d47c37](https://review.byted.org/#/q/0d47c37)), closes [#864](https://jira.bytedance.com/browse/LKI-864)
* **message:** 分享选择和确认 ([dbee0e6](https://review.byted.org/#/q/dbee0e6)), closes [#842](https://jira.bytedance.com/browse/LKI-842)
* **message:** 群分享消息去掉加急和回复 ([1d4b970](https://review.byted.org/#/q/1d4b970)), closes [#878](https://jira.bytedance.com/browse/LKI-878)
* **message:** 解析群名片content ([fe45dbe](https://review.byted.org/#/q/fe45dbe)), closes [#851](https://jira.bytedance.com/browse/LKI-851)



<a name="1.2.5-beta5"></a>
## 1.2.5-beta5 (2017-10-26)


### Bug Fixes

* **chat:** webview体验优化 ([f246a49](https://review.byted.org/#/q/f246a49)), closes [#792](https://jira.bytedance.com/browse/LKI-792)
* **chat:** 加载失败页背景颜色改为不透明 ([14b9031](https://review.byted.org/#/q/14b9031)), closes [#793](https://jira.bytedance.com/browse/LKI-793)
* **chat:** 头条圈上传图片窗口弹出两次 ([8dad535](https://review.byted.org/#/q/8dad535)), closes [#872](https://jira.bytedance.com/browse/LKI-872)
* **chat:** 解决defaultKeyboar引起的崩溃问题 ([7c716c4](https://review.byted.org/#/q/7c716c4)), closes [#862](https://jira.bytedance.com/browse/LKI-862)
* **chat:** 调整表情布局 ([783d988](https://review.byted.org/#/q/783d988)), closes [#868](https://jira.bytedance.com/browse/LKI-868)
* **component:** 一些ui问题修复 ([1801544](https://review.byted.org/#/q/1801544)), closes [#861](https://jira.bytedance.com/browse/LKI-861)
* **component:** 解决ios10上标题栏布局出错的问题 ([1f41ed4](https://review.byted.org/#/q/1f41ed4)), closes [#870](https://jira.bytedance.com/browse/LKI-870)
* **contact:** 修复负责人(未注册)标签布局不对的问题 ([a2d5a35](https://review.byted.org/#/q/a2d5a35)), closes [#869](https://jira.bytedance.com/browse/LKI-869)
* **message:** ChatViewController循环引用问题 ([84a2df0](https://review.byted.org/#/q/84a2df0)), closes [#865](https://jira.bytedance.com/browse/LKI-865)
* **message:** InputView高度变化不主动触发scrollToBottom，否则导致H5scrollTop计算不对 ([ea65392](https://review.byted.org/#/q/ea65392)), closes [#860](https://jira.bytedance.com/browse/LKI-860)


### Features

* **chat:** 推送直达会话 ([d0fe8d5](https://review.byted.org/#/q/d0fe8d5)), closes [#696](https://jira.bytedance.com/browse/LKI-696)
* **contact:** 放开对未注册用户的限制 ([fcad200](https://review.byted.org/#/q/fcad200)), closes [#867](https://jira.bytedance.com/browse/LKI-867)
* **contact:** 离职员工/不同企业员工特殊处理 ([19dcaef](https://review.byted.org/#/q/19dcaef)), closes [#852](https://jira.bytedance.com/browse/LKI-852)



<a name="1.2.5-beta4"></a>
## 1.2.5-beta4 (2017-10-25)


### Bug Fixes

* **chat:** profiel预览没有埋点 ([fff88ba](https://review.byted.org/#/q/fff88ba)), closes [#856](https://jira.bytedance.com/browse/LKI-856)
* **component:** crash修复closes [#839](https://jira.bytedance.com/browse/LKI-839) ([e4a9646](https://review.byted.org/#/q/e4a9646))
* **component:** emoji之间的间距调整 ([cd43cc0](https://review.byted.org/#/q/cd43cc0)), closes [#849](https://jira.bytedance.com/browse/LKI-849)
* **component:** LKLabel在只@自己的情况下pointAtIndex判定bugcloses [#834](https://jira.bytedance.com/browse/LKI-834) ([a5a08b9](https://review.byted.org/#/q/a5a08b9))
* **message:** LKLabel @自己的点击Index判定会出现偏移问题修复 ([2382a49](https://review.byted.org/#/q/2382a49)), closes [#854](https://jira.bytedance.com/browse/LKI-854)
* **message:** 会话页面loading结束后发消息按钮失灵 ([d445c11](https://review.byted.org/#/q/d445c11)), closes [#837](https://jira.bytedance.com/browse/LKI-837)
* **message:** 发消息位置不对 ([ca09a57](https://review.byted.org/#/q/ca09a57)), closes [#848](https://jira.bytedance.com/browse/LKI-848)
* **message:** 回复的消息@别人不走已读未读画点的逻辑closes [#844](https://jira.bytedance.com/browse/LKI-844) ([1dfb41b](https://review.byted.org/#/q/1dfb41b))
* **message:** 已读未读反了 ([73ab403](https://review.byted.org/#/q/73ab403)), closes [#836](https://jira.bytedance.com/browse/LKI-836)
* **message:** 拨打电话cell@自己消失 ([3990697](https://review.byted.org/#/q/3990697)), closes [#859](https://jira.bytedance.com/browse/LKI-859)
* **message:** 搜索页面触发加载大量消息的逻辑bug ([ed3a389](https://review.byted.org/#/q/ed3a389)), closes [#858](https://jira.bytedance.com/browse/LKI-858)
* **message:** 网页浏览体验优化 ([29fe550](https://review.byted.org/#/q/29fe550)), closes [#845](https://jira.bytedance.com/browse/LKI-845)
* **setting:** 有更新时，我的页面加一个“有更新“标记 ([50995fd](https://review.byted.org/#/q/50995fd)), closes [#835](https://jira.bytedance.com/browse/LKI-835)


### Features

* **chat:** 调整提示出现时机 ([8063bd4](https://review.byted.org/#/q/8063bd4)), closes [#788](https://jira.bytedance.com/browse/LKI-788)
* **contact:** 个人名片页头像替换成人脸识别后的头像 ([ad631aa](https://review.byted.org/#/q/ad631aa)), closes [#846](https://jira.bytedance.com/browse/LKI-846)
* **contact:** 名片页点击头像看大图, 长按内容可复制 ([7eab774](https://review.byted.org/#/q/7eab774)), closes [#847](https://jira.bytedance.com/browse/LKI-847)
* **message:** 埋点四期（补充2项）：新版表情 / 切换到已完成 ([2c2a10f](https://review.byted.org/#/q/2c2a10f)), closes [#853](https://jira.bytedance.com/browse/LKI-853)
* **search:** 智能搜索对接场景变量参数 ([b854e57](https://review.byted.org/#/q/b854e57)), closes [#830](https://jira.bytedance.com/browse/LKI-830)



<a name="1.2.5-beta3"></a>
## 1.2.5-beta3 (2017-10-24)


### Bug Fixes

* **chat:** 修复效率提示布局错误的问题 ([bc3b40a](https://review.byted.org/#/q/bc3b40a)), closes [#788](https://jira.bytedance.com/browse/LKI-788)
* **chat:** 浏览器滑动返回和页面返回冲突、编译不过 ([aedc8b5](https://review.byted.org/#/q/aedc8b5)), closes [#833](https://jira.bytedance.com/browse/LKI-833)
* **contact:** 名片页优化 ([7762451](https://review.byted.org/#/q/7762451)), closes [#832](https://jira.bytedance.com/browse/LKI-832)
* **message:** AtPoint大小修改 ([2144b1e](https://review.byted.org/#/q/2144b1e)), closes [#825](https://jira.bytedance.com/browse/LKI-825)
* **message:** iOS11消息cell约束冲突 ([e475d84](https://review.byted.org/#/q/e475d84)), closes [#824](https://jira.bytedance.com/browse/LKI-824)
* **message:** 修改群名称右上角【完成】改为【保存】，与群描述修改统一 ([6e07bc3](https://review.byted.org/#/q/6e07bc3)), closes [#795](https://jira.bytedance.com/browse/LKI-795)
* **message:** 文件消息的已读未读三端一致 ([fbc8ab6](https://review.byted.org/#/q/fbc8ab6)), closes [#816](https://jira.bytedance.com/browse/LKI-816)
* **message:** 表情未对应上 ([9df70bf](https://review.byted.org/#/q/9df70bf)), closes [#806](https://jira.bytedance.com/browse/LKI-806)
* **message:** 语音无法播放 ([295a24a](https://review.byted.org/#/q/295a24a)), closes [#814](https://jira.bytedance.com/browse/LKI-814)
* **search:** 搜索约束冲突 ([7fa4979](https://review.byted.org/#/q/7fa4979)), closes [#822](https://jira.bytedance.com/browse/LKI-822)
* **search:** 搜索页面加载分页死循环, 把上拉控件替换了 ([26c900e](https://review.byted.org/#/q/26c900e)), closes [#819](https://jira.bytedance.com/browse/LKI-819)


### Features

* **chat:** 修复新消息提示图片拉伸 ([6b26f37](https://review.byted.org/#/q/6b26f37)), closes [#823](https://jira.bytedance.com/browse/LKI-823)
* **chat:** 修正提示文案 ([28e3212](https://review.byted.org/#/q/28e3212)), closes [#788](https://jira.bytedance.com/browse/LKI-788)
* **chat:** 头条圈支持分享 ([55dc837](https://review.byted.org/#/q/55dc837)), closes [#818](https://jira.bytedance.com/browse/LKI-818) [#821](https://jira.bytedance.com/browse/LKI-821)
* **chat:** 通过拉chat,判断是否还在群内 ([3aec726](https://review.byted.org/#/q/3aec726)), closes [#826](https://jira.bytedance.com/browse/LKI-826)
* **chat:** 键盘适配iPhoneX ([c28ee80](https://review.byted.org/#/q/c28ee80)), closes [#797](https://jira.bytedance.com/browse/LKI-797)
* **component:** LKLabel支持点击NSRange内的text的回调事件 ([f540837](https://review.byted.org/#/q/f540837)), closes [#815](https://jira.bytedance.com/browse/LKI-815)
* **component:** 客户端埋点四期 ([2599b07](https://review.byted.org/#/q/2599b07)), closes [#798](https://jira.bytedance.com/browse/LKI-798)
* **component:** 支持扫码进入客服群 ([82b8588](https://review.byted.org/#/q/82b8588)), closes [#820](https://jira.bytedance.com/browse/LKI-820)
* **contact:** 个人名片和群名片重构并添加新页面 ([fb80aa3](https://review.byted.org/#/q/fb80aa3)), closes [#656](https://jira.bytedance.com/browse/LKI-656)
* **message:** LKLabel支持LKEmoji ([1be09c7](https://review.byted.org/#/q/1be09c7)), closes [#813](https://jira.bytedance.com/browse/LKI-813)
* **message:** 点击@跳转名片 ([dacde89](https://review.byted.org/#/q/dacde89)), closes [#749](https://jira.bytedance.com/browse/LKI-749)
* **message:** 聊天页面loading样式修改, loading中不允许其他操作 ([6078969](https://review.byted.org/#/q/6078969)), closes [#808](https://jira.bytedance.com/browse/LKI-808)



<a name="1.2.5-beta2"></a>
## 1.2.5-beta2 (2017-10-20)


### Bug Fixes

* **chat:** window.open打开的url时，导航颜色没更新 ([1c7e9b7](https://review.byted.org/#/q/1c7e9b7)), closes [#810](https://jira.bytedance.com/browse/LKI-810)
* **chat:** 修复头条圈看图、一直loading、支持复制 ([d60704c](https://review.byted.org/#/q/d60704c)), closes [#810](https://jira.bytedance.com/browse/LKI-810) [#811](https://jira.bytedance.com/browse/LKI-811)


### Features

* **chat:** 再次修正因百度输入法造成的输入BUG ([9fde3a9](https://review.byted.org/#/q/9fde3a9)), closes [#779](https://jira.bytedance.com/browse/LKI-779)
* **chat:** 支持无标题贴子 ([7e21a46](https://review.byted.org/#/q/7e21a46)), closes [#807](https://jira.bytedance.com/browse/LKI-807)
* **chat:** 添加触发式提醒 ([05c07e0](https://review.byted.org/#/q/05c07e0)), closes [#788](https://jira.bytedance.com/browse/LKI-788)
* **thread:** thread页支持表情 ([1edf3c4](https://review.byted.org/#/q/1edf3c4)), closes [#806](https://jira.bytedance.com/browse/LKI-806)



<a name="1.2.5-beta1"></a>
## 1.2.5-beta1 (2017-10-19)


### Bug Fixes

* **chat:** 修复iOS输入框BUG ([be49f03](https://review.byted.org/#/q/be49f03)), closes [#779](https://jira.bytedance.com/browse/LKI-779)
* **message:** 修复plus机型在iOS10.0系统中message cell会出现挤压的现象 ([050fff8](https://review.byted.org/#/q/050fff8)), closes [#786](https://jira.bytedance.com/browse/LKI-786)


### Features

* **chat:** 侧边栏头图替换 ([75457c7](https://review.byted.org/#/q/75457c7)), closes [#794](https://jira.bytedance.com/browse/LKI-794)
* **chat:** 支持头条圈 ([9f0b336](https://review.byted.org/#/q/9f0b336)), closes [#751](https://jira.bytedance.com/browse/LKI-751) [#752](https://jira.bytedance.com/browse/LKI-752) [#792](https://jira.bytedance.com/browse/LKI-792) [#793](https://jira.bytedance.com/browse/LKI-793)
* **component:** 替换引导页图片 ([0c42dcf](https://review.byted.org/#/q/0c42dcf)), closes [#787](https://jira.bytedance.com/browse/LKI-787)
* **component:** 添加对话Lark团队 ([8adba44](https://review.byted.org/#/q/8adba44)), closes [#787](https://jira.bytedance.com/browse/LKI-787)
* **message:** 修正 emotionHelper ([67aa369](https://review.byted.org/#/q/67aa369)), closes [#790](https://jira.bytedance.com/browse/LKI-790)
* **message:** 表情包输入 ([0380210](https://review.byted.org/#/q/0380210)), closes [#791](https://jira.bytedance.com/browse/LKI-791)
* **setting:** “关于Lark”的页面重构 ([6816f5c](https://review.byted.org/#/q/6816f5c)), closes [#789](https://jira.bytedance.com/browse/LKI-789)
* **setting:** setting 新页面 ([7377467](https://review.byted.org/#/q/7377467)), closes [#692](https://jira.bytedance.com/browse/LKI-692)
* **setting:** 新版本升级弹窗 ([9109fc8](https://review.byted.org/#/q/9109fc8)), closes [#692](https://jira.bytedance.com/browse/LKI-692)



<a name="1.2.1"></a>
## 1.2.1 (2017-10-13)


### Bug Fixes

* **message:** idletimerdisable设置应在主线程 ([2c4a8fe](https://review.byted.org/#/q/2c4a8fe)), closes [#784](https://jira.bytedance.com/browse/LKI-784)
* **message:** 键盘弹起偶尔不会滚动到列表底部的问题 ([3aef2e4](https://review.byted.org/#/q/3aef2e4)), closes [#777](https://jira.bytedance.com/browse/LKI-777)



<a name="1.2.1-beta1"></a>
## 1.2.1-beta1 (2017-10-12)


### Bug Fixes

* **chat:** 头像不支持GIF ([6d7de57](https://review.byted.org/#/q/6d7de57)), closes [#775](https://jira.bytedance.com/browse/LKI-775)
* **chat:** 客服群一直是关闭通知 ([de63d16](https://review.byted.org/#/q/de63d16)), closes [#778](https://jira.bytedance.com/browse/LKI-778)
* **chat:** 微调了swipeCell的触发顺序,预防bug ([0b39d90](https://review.byted.org/#/q/0b39d90)), closes [#000](https://jira.bytedance.com/browse/LKI-000)
* **chat:** 自己发的消息显示为别人的名字 ([037c703](https://review.byted.org/#/q/037c703)), closes [#761](https://jira.bytedance.com/browse/LKI-761)
* **chat:** 首页左滑能同时滑动两条cell ([9a22478](https://review.byted.org/#/q/9a22478)), closes [#771](https://jira.bytedance.com/browse/LKI-771)
* **component:** webview使用新窗口打开新链接崩溃 ([d5d3ebe](https://review.byted.org/#/q/d5d3ebe)), closes [#780](https://jira.bytedance.com/browse/LKI-780)
* **component:** 修复引导页透明度BUG ([522cb57](https://review.byted.org/#/q/522cb57)), closes [#750](https://jira.bytedance.com/browse/LKI-750)
* **login:** 新的二维码扫描代理对接 ([b14729a](https://review.byted.org/#/q/b14729a)), closes [#757](https://jira.bytedance.com/browse/LKI-757)
* **message:** 修复iOS11输入框复制问题 ([947198a](https://review.byted.org/#/q/947198a)), closes [#779](https://jira.bytedance.com/browse/LKI-779)
* **message:** 修复语音播放过程中进入已读未读页仍在播放的问题 ([e5fd2fe](https://review.byted.org/#/q/e5fd2fe)), closes [#774](https://jira.bytedance.com/browse/LKI-774)
* **message:** 点击新消息气泡新消息没有跳出来 ([700502f](https://review.byted.org/#/q/700502f)), closes [#754](https://jira.bytedance.com/browse/LKI-754)
* **message:** 自己发出的消息不滚动到底部的问题 ([6ce7979](https://review.byted.org/#/q/6ce7979)), closes [#777](https://jira.bytedance.com/browse/LKI-777)
* **thread:** Thread页无法文件无法打开 ([4b91b7a](https://review.byted.org/#/q/4b91b7a)), closes [#773](https://jira.bytedance.com/browse/LKI-773)


### Features

* **message:** 发富文本改成同回复使用富文本的展示样式一致 ([a5c54dd](https://review.byted.org/#/q/a5c54dd)), closes [#759](https://jira.bytedance.com/browse/LKI-759)



<a name="1.2.0"></a>
# 1.2.0 (2017-09-26)


### Bug Fixes

* **chat:** 首页单聊未读没更新 ([dd284cb](https://review.byted.org/#/q/dd284cb)), closes [#746](https://jira.bytedance.com/browse/LKI-746)
* **component:** 解决版本号正则匹配错误的问题 ([74b3c9f](https://review.byted.org/#/q/74b3c9f)), closes [#747](https://jira.bytedance.com/browse/LKI-747)
* **message:** iOS11自己发的消息会跳动,修复 ([85d49d2](https://review.byted.org/#/q/85d49d2)), closes [#728](https://jira.bytedance.com/browse/LKI-728)
* **message:** PostContent和TextContent的长度截取逻辑重复，抽取一个功用逻辑 ([2577787](https://review.byted.org/#/q/2577787)), closes [#745](https://jira.bytedance.com/browse/LKI-745)
* **message:** 转发消息需要带上 parentSourceId 和 rootSourceId ([1d4d90a](https://review.byted.org/#/q/1d4d90a)), closes [#748](https://jira.bytedance.com/browse/LKI-748)



<a name="1.2.0-beta10"></a>
# 1.2.0-beta10 (2017-09-25)


### Bug Fixes

* **component:** 修复 LKLabel 内部循环引用问题 ([d416d3a](https://review.byted.org/#/q/d416d3a)), closes [#732](https://jira.bytedance.com/browse/LKI-732)
* **message:** syncMessageReadStatus过滤逻辑调整 ([1506a4d](https://review.byted.org/#/q/1506a4d)), closes [#743](https://jira.bytedance.com/browse/LKI-743)
* **message:** 修复展示失败的图片会crash的问题 ([57ee1e5](https://review.byted.org/#/q/57ee1e5)), closes [#742](https://jira.bytedance.com/browse/LKI-742)
* **message:** 修复点击新消息气泡下拉控件消失的bug没解干净 ([4237ae5](https://review.byted.org/#/q/4237ae5)), closes [#727](https://jira.bytedance.com/browse/LKI-727)
* **message:** 修复超长文本加载卡顿的问题 ([3c7711b](https://review.byted.org/#/q/3c7711b)), closes [#744](https://jira.bytedance.com/browse/LKI-744)
* **message:** 去掉进入已读未读列表的状态限制, memberCount仍然有可能为-1,导致无法跳转 ([cef0aa4](https://review.byted.org/#/q/cef0aa4)), closes [#729](https://jira.bytedance.com/browse/LKI-729)
* **message:** 富文本回复的消息截断优化 ([c0f5829](https://review.byted.org/#/q/c0f5829)), closes [#715](https://jira.bytedance.com/browse/LKI-715)
* **message:** 点击新消息气泡下拉加载更多消失 ([1842aa7](https://review.byted.org/#/q/1842aa7)), closes [#727](https://jira.bytedance.com/browse/LKI-727)
* **message:** 长段英文文本系统 AutoLayout 计算有 bug, 导致无法撑开 cell ([d29f0e3](https://review.byted.org/#/q/d29f0e3)), closes [#733](https://jira.bytedance.com/browse/LKI-733)
* **thread:** 修复发帖插图上墙阻塞主线程的问题 ([5f84e00](https://review.byted.org/#/q/5f84e00)), closes [#730](https://jira.bytedance.com/browse/LKI-730)


### Features

* **chat:** 已完成多端同步 ([23ac66d](https://review.byted.org/#/q/23ac66d)), closes [#726](https://jira.bytedance.com/browse/LKI-726) [#725](https://jira.bytedance.com/browse/LKI-725) [#725](https://jira.bytedance.com/browse/LKI-725) [#735](https://jira.bytedance.com/browse/LKI-735)
* **component:** 键盘组件View懒加载 ([908fe72](https://review.byted.org/#/q/908fe72)), closes [#723](https://jira.bytedance.com/browse/LKI-723)
* **search:** 支持智能搜索 ([fb6ba95](https://review.byted.org/#/q/fb6ba95)), closes [#722](https://jira.bytedance.com/browse/LKI-722)


### Performance Improvements

* **component:** LKTextRenderEngine处理最后一行逻辑性能简单提升 ([8c8c20f](https://review.byted.org/#/q/8c8c20f)), closes [#731](https://jira.bytedance.com/browse/LKI-731)
* **message:** 进入聊天页面耗时 性能调优 ([2bc11f5](https://review.byted.org/#/q/2bc11f5)), closes [#724](https://jira.bytedance.com/browse/LKI-724)



<a name="1.2.0-beta9"></a>
# 1.2.0-beta9 (2017-09-21)


### Bug Fixes

* **component:** webview返回按钮文案固定 ([4f5a42a](https://review.byted.org/#/q/4f5a42a)), closes [#721](https://jira.bytedance.com/browse/LKI-721)
* **component:** 优化引导页交互 ([eee0569](https://review.byted.org/#/q/eee0569)), closes [#712](https://jira.bytedance.com/browse/LKI-712)
* **component:** 适配 iOS 11 tableView footerView 高度 ([a95f19e](https://review.byted.org/#/q/a95f19e)), closes [#718](https://jira.bytedance.com/browse/LKI-718)
* **message:** 下拉刷新bug ([8dd84b5](https://review.byted.org/#/q/8dd84b5)), closes [#714](https://jira.bytedance.com/browse/LKI-714)
* **message:** 修复数据库中回复数被错误值冲掉的问题 ([8969fdc](https://review.byted.org/#/q/8969fdc)), closes [#719](https://jira.bytedance.com/browse/LKI-719)
* **message:** 修改发帖时转化HTML多余的换行问题 ([d3c1735](https://review.byted.org/#/q/d3c1735)), closes [#720](https://jira.bytedance.com/browse/LKI-720)
* **message:** 图片消息解析支持属性匹配 ([1a72e93](https://review.byted.org/#/q/1a72e93)), closes [#709](https://jira.bytedance.com/browse/LKI-709)
* **message:** 富文本回复，图文显示规则调整; collectionView, textView iOS11 适配 ([0265ca5](https://review.byted.org/#/q/0265ca5)), closes [#715](https://jira.bytedance.com/browse/LKI-715)
* **setting:** 修复profile页背景高度不够问题 ([9817162](https://review.byted.org/#/q/9817162)), closes [#711](https://jira.bytedance.com/browse/LKI-711)
* **thread:** 详情页自己发消息滚动到底部 ([2245749](https://review.byted.org/#/q/2245749)), closes [#713](https://jira.bytedance.com/browse/LKI-713)


### Features

* **message:** 被截断的消息一定展示查看全部 ([ca21830](https://review.byted.org/#/q/ca21830)), closes [#709](https://jira.bytedance.com/browse/LKI-709)
* **thread:** 消息详情页支持对transcated消息的处理 ([eab23c3](https://review.byted.org/#/q/eab23c3)), closes [#706](https://jira.bytedance.com/browse/LKI-706)



<a name="1.2.0-beta8"></a>
# 1.2.0-beta8 (2017-09-20)


### Bug Fixes

* chatvc进入其他页返回时页面滚动 ([701d2d9](https://review.byted.org/#/q/701d2d9))
* pack别人ding我的消息的isShowDing逻辑补充 ([26575c0](https://review.byted.org/#/q/26575c0))
* pull unreadCount触发MessageUnreadCountObserver ([5a8ebaa](https://review.byted.org/#/q/5a8ebaa)), closes [#707](https://jira.bytedance.com/browse/LKI-707)
* remove warning ([cf8b34b](https://review.byted.org/#/q/cf8b34b))
* 一些界面contentInsetAdjustmentBehavior补全 ([f1625ff](https://review.byted.org/#/q/f1625ff))
* 下拉不下数据问题 ([a6cf283](https://review.byted.org/#/q/a6cf283))
* 优化了tableView刷新的机制, 预防各种诡异的跳动 ([e872f3a](https://review.byted.org/#/q/e872f3a))
* 修复 iOS10 titleView 布局问题 ([d522618](https://review.byted.org/#/q/d522618)), closes [#702](https://jira.bytedance.com/browse/LKI-702)
* 修复 iOS11 titleView 过度状态消失的BUG ([f72c74d](https://review.byted.org/#/q/f72c74d)), closes [#708](https://jira.bytedance.com/browse/LKI-708)
* 修复@人状态更新错误的问题 ([49b7ae5](https://review.byted.org/#/q/49b7ae5))
* 修复title view 过长遮盖问题 ([9512b80](https://review.byted.org/#/q/9512b80)), closes [#702](https://jira.bytedance.com/browse/LKI-702)
* 修复Urgent多端confirm不同步的问题 ([4389464](https://review.byted.org/#/q/4389464))
* 修复在iOS11下,从聊天列表页右滑返回搜索结果页,导致搜索结果页面滚动的问题 ([4891b4e](https://review.byted.org/#/q/4891b4e))
* 修复自己发长文本消息时状态 loading 被压扁的问题 ([f82ac7f](https://review.byted.org/#/q/f82ac7f))
* 修复长按 cell 头像背景色消失, 已读未读不跳转的问题 ([bb433c5](https://review.byted.org/#/q/bb433c5))
* 修正引导页面UI ([18ab07b](https://review.byted.org/#/q/18ab07b))
* 打不开链接不跳转 ([fb5b18b](https://review.byted.org/#/q/fb5b18b))
* 支持登录wiki ([6078b25](https://review.byted.org/#/q/6078b25))
* 新消息来滚动时候总是弹出一条新消息 ([5ae7f48](https://review.byted.org/#/q/5ae7f48))
* 消息存库，字段被冲掉 ([b130d16](https://review.byted.org/#/q/b130d16))
* 消息成功更新position ([f09b3cb](https://review.byted.org/#/q/f09b3cb))
* 聊天里未显示未读数 ([fd3a1c3](https://review.byted.org/#/q/fd3a1c3))
* 详情页信号调整 ([bcf6c5d](https://review.byted.org/#/q/bcf6c5d))
* 转发到当前群消息状态未更新 ([b21d1ff](https://review.byted.org/#/q/b21d1ff))
* 适配ios11相关的跳动问题 ([4f1d093](https://review.byted.org/#/q/4f1d093))
* 通知不在主线程 ([9b42970](https://review.byted.org/#/q/9b42970))


### Features

* tab和checkbox支持震动 ([b1abf1e](https://review.byted.org/#/q/b1abf1e))
* 增加可以跳转的app的白名单 ([0dfa4b4](https://review.byted.org/#/q/0dfa4b4))
* 添加侧边栏引导页 ([fa4c907](https://review.byted.org/#/q/fa4c907))



<a name="1.2.0-beta7"></a>
# 1.2.0-beta7 (2017-09-18)


### Bug Fixes

* at气泡和新消息气泡同时出现 ([55d0fdd](https://review.byted.org/#/q/55d0fdd))
* chatViewController iOS11 滚动问题修复 ([db04b7e](https://review.byted.org/#/q/db04b7e))
* ios11 cell滑动适配 ([7a59fe4](https://review.byted.org/#/q/7a59fe4))
* PackUnreadCount不能将正确的数据更新到内存中的bug ([b90ebdf](https://review.byted.org/#/q/b90ebdf))
* webview会打开多个 ([cedff8d](https://review.byted.org/#/q/cedff8d))
* webView适配iOS11 ([c88bdde](https://review.byted.org/#/q/c88bdde)), closes [#701](https://jira.bytedance.com/browse/LKI-701)
* 优化刷新组件 ([c3c2bb6](https://review.byted.org/#/q/c3c2bb6))
* 会话列表滚动bug ([c6bbfc5](https://review.byted.org/#/q/c6bbfc5))
* 修复在 systemContent 里从数据库加载 userModel 死锁的问题 ([117645b](https://review.byted.org/#/q/117645b))
* 修改拨打电话消息在会话列表中展示文案 ([bde49d8](https://review.byted.org/#/q/bde49d8))
* 修正消息详情页面遮挡问题 ([226e460](https://review.byted.org/#/q/226e460))
* 图片无法重发，test无法跑起来 ([d041fa7](https://review.byted.org/#/q/d041fa7))
* 多发图片闪动问题 ([1ad8e35](https://review.byted.org/#/q/1ad8e35))
* 抽离已读未读逻辑，解决已读未读不准确bug ([7760321](https://review.byted.org/#/q/7760321)), closes [#689](https://jira.bytedance.com/browse/LKI-689)
* 消息发送完成删除resource表数据 ([c21e61c](https://review.byted.org/#/q/c21e61c))
* 清除冗余消息 ([9690d97](https://review.byted.org/#/q/9690d97))
* 给机器人发消息立即已读 ([81f427e](https://review.byted.org/#/q/81f427e))
* 让所有单元测试通过, 修复数据库主键未转化问题 ([ba0e4f5](https://review.byted.org/#/q/ba0e4f5)), closes [#700](https://jira.bytedance.com/browse/LKI-700)
* 资源发送成功时，清理冗余的资源记录 ([e4ac96b](https://review.byted.org/#/q/e4ac96b))
* 进聊天界面不自动刷新 ([ed0b74a](https://review.byted.org/#/q/ed0b74a))
* 适配 iOS11 navbar title 布局错误问题 ([28b553d](https://review.byted.org/#/q/28b553d))
* 键盘弹起滚动入队列 ([2fab80b](https://review.byted.org/#/q/2fab80b))


### Features

* LKLabel testShowMoreButton test未通过修复 ([31e4f10](https://review.byted.org/#/q/31e4f10)), closes [#699](https://jira.bytedance.com/browse/LKI-699)



<a name="1.2.0-beta6"></a>
# 1.2.0-beta6 (2017-09-12)


### Bug Fixes

* messageDetail页scrollToBottom功能增加 ([c16e4f9](https://review.byted.org/#/q/c16e4f9))
* remove assert ([08ed007](https://review.byted.org/#/q/08ed007))
* search拉取历史记录接口修改 ([f473c40](https://review.byted.org/#/q/f473c40))
* Unit Test无法跑过的问题 ([2c25dd8](https://review.byted.org/#/q/2c25dd8))
* unread相关没有进入数据库中 ([acf89e4](https://review.byted.org/#/q/acf89e4))
* 修复 LKLabel 查看全部不能点击的问题; 富文本回复文字显示行数修改 ([57119b6](https://review.byted.org/#/q/57119b6))
* 修复 LKLabel 的部分问题 ([43df5f2](https://review.byted.org/#/q/43df5f2))
* 修复 webview session 释放问题 ([72606c0](https://review.byted.org/#/q/72606c0))
* 修复发空消息问题 ([26f8a6f](https://review.byted.org/#/q/26f8a6f))
* 修改群名称接口替换 ([c56e787](https://review.byted.org/#/q/c56e787))
* 初始消息已读包含自己 ([e0b07f3](https://review.byted.org/#/q/e0b07f3))
* 回复数不对 ([08d64fc](https://review.byted.org/#/q/08d64fc))
* 尝试着解决第一次进入会话消息定位不准的问题 ([363c647](https://review.byted.org/#/q/363c647))
* 已读插入数据库错误 ([b3d9d35](https://review.byted.org/#/q/b3d9d35))
* 拦截系统消息和撤销消息 ([257a220](https://review.byted.org/#/q/257a220))
* 收到消息添加未读数 ([1eb89cc](https://review.byted.org/#/q/1eb89cc))
* 无法发送语音 ([56bed88](https://review.byted.org/#/q/56bed88))
* 版本请求,消息转化优化; 头像组件全局替换 ([77aa957](https://review.byted.org/#/q/77aa957))
* 管子里来的撤回消息没有正确显示、修复propertyMap的问题、修复发消息不更新的问题 ([bbf848b](https://review.byted.org/#/q/bbf848b))
* 网络弹窗逻辑微调 ([2d464d2](https://review.byted.org/#/q/2d464d2))
* 群里只有一个人，发消息立即置为已读 ([23cb6f7](https://review.byted.org/#/q/23cb6f7))
* 自己给自己发消息立即已读 ([71f865f](https://review.byted.org/#/q/71f865f))
* 阅读详情页循环引用 ([948ff13](https://review.byted.org/#/q/948ff13))


### Features

* “收件箱”和“已完成”增加空白占位页面 ([ca78a30](https://review.byted.org/#/q/ca78a30))
* 图片选择器图片更换 ([676fcf9](https://review.byted.org/#/q/676fcf9))
* 更换消息已读状态的引导图 ([a8e004b](https://review.byted.org/#/q/a8e004b))
* 阅读状态使用新的颜色和icon ([3308bfe](https://review.byted.org/#/q/3308bfe))



<a name="1.2.0-beta5"></a>
# 1.2.0-beta5 (2017-09-10)


### Bug Fixes

* cell显示Bug修复 ([7313ada](https://review.byted.org/#/q/7313ada))
* deleteCell Bug fix ([a9154ce](https://review.byted.org/#/q/a9154ce))
* message picker bug fix ([b3ea27b](https://review.byted.org/#/q/b3ea27b))
* swipeCell 加入状态回调 ([471e810](https://review.byted.org/#/q/471e810))
* swipeCell 调整 ([0fa36c3](https://review.byted.org/#/q/0fa36c3))
* WKWebView总弹出登录过期的问题 ([5820a3d](https://review.byted.org/#/q/5820a3d)), closes [#693](https://jira.bytedance.com/browse/LKI-693)
* 修复贴子草稿无法存储BUG ([e93368c](https://review.byted.org/#/q/e93368c))
* 修复贴子页面焦点逻辑 ([cccdb83](https://review.byted.org/#/q/cccdb83))
* 修复部分显示问题 ([9cf7bb8](https://review.byted.org/#/q/9cf7bb8))
* 导航渐变、回复数不更新、转发不显示icon ([bcfd280](https://review.byted.org/#/q/bcfd280))
* 文件摘要显示解析错误、发送文件没显示文件名 ([584fef2](https://review.byted.org/#/q/584fef2))
* 新消息浮窗bug ([433776f](https://review.byted.org/#/q/433776f))


### Features

* WebViewController unregisterLoginWhiteList ([3a1035c](https://review.byted.org/#/q/3a1035c))
* 侧边栏顶部样式调整 ([ca2538b](https://review.byted.org/#/q/ca2538b))
* 支持发送原图 ([50e1cd3](https://review.byted.org/#/q/50e1cd3))


### Performance Improvements

* getNiceDate加缓存 ([ecab37f](https://review.byted.org/#/q/ecab37f))



<a name="1.2.0-beta4"></a>
# 1.2.0-beta4 (2017-09-08)


### Bug Fixes

* cell点击变绿 ([a551087](https://review.byted.org/#/q/a551087))
* status bar 动态获取 ([0b23a56](https://review.byted.org/#/q/0b23a56))
* swipeCell bug fix ([6b32909](https://review.byted.org/#/q/6b32909))
* swipeCell bug fix ([bb558ea](https://review.byted.org/#/q/bb558ea))
* swipeCell Bug fix.... ([438157a](https://review.byted.org/#/q/438157a))
* 一些bug修改 ([0ae392f](https://review.byted.org/#/q/0ae392f))
* 不是isFromMe的消息不应该drawAtPoint ([c10ce54](https://review.byted.org/#/q/c10ce54))
* 修复feed 收件箱cell reuse问题 ([256cec5](https://review.byted.org/#/q/256cec5))
* 修复图片失败重试BUG ([27414bb](https://review.byted.org/#/q/27414bb))
* 修复搜索联系人未注册bug ([f96f97b](https://review.byted.org/#/q/f96f97b))
* 修改个人页icon ([c5a0b3f](https://review.byted.org/#/q/c5a0b3f))
* 修正客服群上传日志逻辑 ([dc9b682](https://review.byted.org/#/q/dc9b682))
* 删除处理时间多余的逻辑判断 ([d56bdc7](https://review.byted.org/#/q/d56bdc7))
* 发post支持origin-width、origin-height带小数点的问题 ([c0241b0](https://review.byted.org/#/q/c0241b0))
* 处理贴子页旋转问题 ([26856b8](https://review.byted.org/#/q/26856b8))
* 已完成支持双击找下一个未读 ([f53e9a1](https://review.byted.org/#/q/f53e9a1))
* 拆分自己发的消息 cell ([770d715](https://review.byted.org/#/q/770d715))
* 暂时把加急语音卡片的未读小红点去掉,且播放不发hasRead ([5b2d29e](https://review.byted.org/#/q/5b2d29e))
* 更新message-detail ([375d2bc](https://review.byted.org/#/q/375d2bc))
* 移除不必要assert ([0761457](https://review.byted.org/#/q/0761457))
* 设置应用BadgeNumber ([267510a](https://review.byted.org/#/q/267510a))
* 高亮的颜色统一 ([93eb81b](https://review.byted.org/#/q/93eb81b)), closes [#648](https://jira.bytedance.com/browse/LKI-648)


### Features

* chat表增加doneTime字段 ([8d0e4c8](https://review.byted.org/#/q/8d0e4c8))
* DraftModel拆分&&发帖子支持origin-width origin-height&&详情页滚动到底优化 ([8ff2282](https://review.byted.org/#/q/8ff2282))
* feedTitle动态改变、feedCell时间更新 ([b4bdf47](https://review.byted.org/#/q/b4bdf47))
* h5滚动设置外部title体验优化 ([3e9fd64](https://review.byted.org/#/q/3e9fd64)), closes [#684](https://jira.bytedance.com/browse/LKI-684)
* PostContent && TextContent逻辑拆分整理 ([1e8e8a4](https://review.byted.org/#/q/1e8e8a4))
* 为“收件箱”和“已完成”分别提供数据 ([cef4160](https://review.byted.org/#/q/cef4160))
* 侧边栏 ([65ba55a](https://review.byted.org/#/q/65ba55a))
* 升级版本提示和更新版本功能改进 ([7d77eae](https://review.byted.org/#/q/7d77eae))
* 发送消息重构 ([fec4139](https://review.byted.org/#/q/fec4139)), closes [#669](https://jira.bytedance.com/browse/LKI-669)
* 左滑动画 ([9959cee](https://review.byted.org/#/q/9959cee))
* 打点三期 ([b9cfd61](https://review.byted.org/#/q/b9cfd61)), closes [#680](https://jira.bytedance.com/browse/LKI-680)
* 撤回消息不显示未读 ([d6592af](https://review.byted.org/#/q/d6592af))
* 撤回的消息按照普通消息一样正常显示 ([2a2a2d7](https://review.byted.org/#/q/2a2a2d7))
* 支持左上角红点和tab badge切换 ([62a2c31](https://review.byted.org/#/q/62a2c31))
* 替换tabbar icon，支持动态切换 ([6a64d79](https://review.byted.org/#/q/6a64d79))
* 添加侧边栏不提醒小红点，修复已完成左上角小红点显示逻辑Bug ([9213493](https://review.byted.org/#/q/9213493))
* 网络弹窗 ([7a75304](https://review.byted.org/#/q/7a75304))
* 首页cell样式修改 ([392f4f5](https://review.byted.org/#/q/392f4f5))
* 首页TitleView样式修改 ([dc31190](https://review.byted.org/#/q/dc31190))



<a name="1.2.0-beta3"></a>
# 1.2.0-beta3 (2017-09-06)


### Bug Fixes

* cell 高亮bug ([172cf70](https://review.byted.org/#/q/172cf70))
* deviceid 重试机制放到登录页面 ([94a8aed](https://review.byted.org/#/q/94a8aed))
* LKLabel bug修复 ([14fbaf1](https://review.byted.org/#/q/14fbaf1)), closes [#610](https://jira.bytedance.com/browse/LKI-610)
* LKLabel LKTextRun getOrigin bug可能会导致野指针问题修复 ([aa78979](https://review.byted.org/#/q/aa78979))
* messagepicker 加载最新消息, 超出限制检测 ([bc44652](https://review.byted.org/#/q/bc44652))
* 优化富文本回复图片加载和修复约束 ([cdcd691](https://review.byted.org/#/q/cdcd691))
* 修复LKLabel pointAt outOfRange判断出错的bug ([0e6071c](https://review.byted.org/#/q/0e6071c))
* 修复刷新组件移除菊花后无法重复加载菊花的bug ([009b2cc](https://review.byted.org/#/q/009b2cc))
* 修复引导页出现时机错误 ([125c389](https://review.byted.org/#/q/125c389))
* 修复消息状态显示Bug ([fa87683](https://review.byted.org/#/q/fa87683))
* 修复长按消息菜单偶发不出现的问题 ([745b260](https://review.byted.org/#/q/745b260))
* 修改保存图片按钮的透明度为70% ([8a9ab49](https://review.byted.org/#/q/8a9ab49))
* 修改已读未读进度显示 ([1c0241b](https://review.byted.org/#/q/1c0241b))
* 加急卡片头像文字大小调整 ([e1393f0](https://review.byted.org/#/q/e1393f0))
* 加急电话更新后更新本地通讯录 ([60f71f1](https://review.byted.org/#/q/60f71f1))
* 单聊建群未同步消息不传ChatId ([deb78f9](https://review.byted.org/#/q/deb78f9))
* 拨打电话消息文字颜色修改; 富文本回复图片加边框 ([c6385af](https://review.byted.org/#/q/c6385af))
* 拨打电话消息颜色修改 ([d0a96b0](https://review.byted.org/#/q/d0a96b0))
* 拨打电话系统消息增加@功能 ([6e3bd2c](https://review.byted.org/#/q/6e3bd2c))
* 消息丢失时carsh(服务器bug触发) ([2fe51ca](https://review.byted.org/#/q/2fe51ca))
* 点赞顺序不对 ([4f5d410](https://review.byted.org/#/q/4f5d410))
* 登录页输入手机号文字居中 ([3b76c70](https://review.byted.org/#/q/3b76c70))
* 聊天滚动修复 ([adc7722](https://review.byted.org/#/q/adc7722))
* 退出登录按钮上移 ([ead65bb](https://review.byted.org/#/q/ead65bb))
* 长摁人头像At键盘弹起滚动不到底部的问题修复 ([899149b](https://review.byted.org/#/q/899149b))
* 首页cell最近消息去除行头 换行&空格 ([21e1f30](https://review.byted.org/#/q/21e1f30))


### Features

* @支持多选 ([3ad76fd](https://review.byted.org/#/q/3ad76fd))
* feedlist显示单聊最后一条消息的阅读状态 ([e85bce1](https://review.byted.org/#/q/e85bce1))
* LKLabel重构，拆分出Layout和Render ([e52e61f](https://review.byted.org/#/q/e52e61f)), closes [#647](https://jira.bytedance.com/browse/LKI-647)
* LKMessageModel逻辑代码拆分 ([9c98d63](https://review.byted.org/#/q/9c98d63))
* LKMessageModel逻辑拆分 ([1aca31d](https://review.byted.org/#/q/1aca31d)), closes [#646](https://jira.bytedance.com/browse/LKI-646)
* LKTextLayoutEngine性能优化 && 单测性能测试 ([f9a9896](https://review.byted.org/#/q/f9a9896))
* MessagePO内逻辑整理 ([7f06fde](https://review.byted.org/#/q/7f06fde)), closes [#672](https://jira.bytedance.com/browse/LKI-672)
* 优化会话列表水印 ([bcd0eaa](https://review.byted.org/#/q/bcd0eaa))
* 保存图片按钮5秒后消失 ([b6ffba6](https://review.byted.org/#/q/b6ffba6)), closes [#661](https://jira.bytedance.com/browse/LKI-661)
* 分支初始化 ([d1f7783](https://review.byted.org/#/q/d1f7783))
* 加急界面显示已读／未读状态 ([5b5e8b0](https://review.byted.org/#/q/5b5e8b0))
* 加急确认本地通知消息拼接 ([7ccc566](https://review.byted.org/#/q/7ccc566))
* 基本完成加急三期逻辑（反复加急、已读未读数） ([8793772](https://review.byted.org/#/q/8793772))
* 提供加急电话通讯录操作方法 ([738e2ec](https://review.byted.org/#/q/738e2ec))
* 提供加急类型 ([61587e8](https://review.byted.org/#/q/61587e8))
* 搜索历史记录机器人 ([3f5aa8a](https://review.byted.org/#/q/3f5aa8a))
* 支持消息截断 ([14a0b14](https://review.byted.org/#/q/14a0b14)), closes [#660](https://jira.bytedance.com/browse/LKI-660)
* 数据库表操作提供带db的方法，单测改为测试含有db的方法 ([b40e636](https://review.byted.org/#/q/b40e636))
* 消息摘要去除[帖子] ([4d8c7c3](https://review.byted.org/#/q/4d8c7c3))
* 添加加急电话号码提醒设置 ([6b182eb](https://review.byted.org/#/q/6b182eb))
* 添加客服会话上传日志的功能 ([3f3a7c7](https://review.byted.org/#/q/3f3a7c7))
* 第一次电话加急提醒 ([d9f30c5](https://review.byted.org/#/q/d9f30c5))
* 详情页创建使用工厂方法 ([6e5c8c8](https://review.byted.org/#/q/6e5c8c8))
* 语音消息支持加急 ([e1643df](https://review.byted.org/#/q/e1643df))
* 转发时搜索结果，完全匹配的排在第一个 ([d99305a](https://review.byted.org/#/q/d99305a))
* 重做搜索历史记录 ([b01fa8d](https://review.byted.org/#/q/b01fa8d))
* 重复加急'加急未读'标签 ([b98a582](https://review.byted.org/#/q/b98a582))
* 重复加急选人时已加急过的人自动选中 ([bdb0d9a](https://review.byted.org/#/q/bdb0d9a))


### Performance Improvements

* 搜索优化 ([02bc122](https://review.byted.org/#/q/02bc122))
* 群消息已读push太多，增加缓冲降频处理 ([269156a](https://review.byted.org/#/q/269156a))



<a name="1.2.0-beta2"></a>
# 1.2.0-beta2 (2017-08-29)


### Bug Fixes

* chatViewController 瘦身 ([540d371](https://review.byted.org/#/q/540d371))
* fix some bugs ([391fce8](https://review.byted.org/#/q/391fce8))
* WebViewController crash修复 ([ad93902](https://review.byted.org/#/q/ad93902))
* 再次修复和陌生人聊天没有title的问题 ([320813e](https://review.byted.org/#/q/320813e))
* 单聊navigationitem间距调整 ([97d1f90](https://review.byted.org/#/q/97d1f90))
* 已读未读显示图标可见度改善 ([b2891e5](https://review.byted.org/#/q/b2891e5))
* 文案错别字修改 ([bf7c5eb](https://review.byted.org/#/q/bf7c5eb)), closes [#617](https://jira.bytedance.com/browse/LKI-617)
* 查看头像大图时不显示保存图片的按钮 ([7382e32](https://review.byted.org/#/q/7382e32))
* 水印拉取频率控制bug修复 ([6b9e970](https://review.byted.org/#/q/6b9e970))


### Features

* 单聊接chatModel改变信号 ([095dffa](https://review.byted.org/#/q/095dffa))
* 回复消息支持富文本回复 ([1e0672f](https://review.byted.org/#/q/1e0672f))
* 增加数据操作方法 ([9f40395](https://review.byted.org/#/q/9f40395))
* 拨打电话系统消息增加推送通知 ([e9c87bf](https://review.byted.org/#/q/e9c87bf))



<a name="1.1.6"></a>
## 1.1.6 (2017-08-27)


### Bug Fixes

* postContent @自己 长度计算问题 ([ca7ce82](https://review.byted.org/#/q/ca7ce82))
* 修复LKLabel firstAtPoint坐标系不是view坐标系的问题 ([c079b39](https://review.byted.org/#/q/c079b39))
* 修改部分建表语句和Column ([c8db038](https://review.byted.org/#/q/c8db038))
* 增加一个单聊ding已读未读的纠错逻辑 ([9de1ac5](https://review.byted.org/#/q/9de1ac5))
* 帮助与反馈无法打开、反馈群默认不通知、富文本点击崩溃 ([8afe561](https://review.byted.org/#/q/8afe561))


### Features

* 补充dataaccess数据操作方法 ([63919bf](https://review.byted.org/#/q/63919bf))



<a name="1.2.0-beta1"></a>
# 1.2.0-beta1 (2017-08-25)


### Bug Fixes

* @人一处文案修改 ([5209d17](https://review.byted.org/#/q/5209d17))
* @所有人 的已读未读优化逻辑补全 ([ad465bf](https://review.byted.org/#/q/ad465bf)), closes [#622](https://jira.bytedance.com/browse/LKI-622)
* backgroundView 优化 ([b230e8f](https://review.byted.org/#/q/b230e8f))
* install-hook脚本执行失败 ([67c6614](https://review.byted.org/#/q/67c6614))
* lki606已读未读状态丢失 ([9d2a965](https://review.byted.org/#/q/9d2a965))
* message picker UI Fix ([8c8f89e](https://review.byted.org/#/q/8c8f89e))
* message 跳转逻辑完善 ([aced50a](https://review.byted.org/#/q/aced50a))
* MessageMemberRefDataAccess.update(fmdb: FMDatabase, messagePO: MessagePO, columns: [Column]) sql use messageId not id bug ([07f726d](https://review.byted.org/#/q/07f726d))
* MessageMemberRef表update错误 ([a2f7063](https://review.byted.org/#/q/a2f7063))
* messagepicker bug修复 ([2666605](https://review.byted.org/#/q/2666605))
* Message已读未读入库的逻辑bug fix && ding已读未读入库的逻辑bug fix ([c7df43d](https://review.byted.org/#/q/c7df43d))
* newMessageSign上的时间使用的不是离它最近的消息的时间的bug ([83b4c27](https://review.byted.org/#/q/83b4c27))
* NSAttributedString+Lark.swift add in LarkDev ([69974ef](https://review.byted.org/#/q/69974ef))
* packDingUnreadCont拆解 && 填补部分unread逻辑漏洞 ([1b36dd5](https://review.byted.org/#/q/1b36dd5))
* profile支持传入usermodel ([7d22d9a](https://review.byted.org/#/q/7d22d9a))
* select line style ([d44b228](https://review.byted.org/#/q/d44b228))
* task queue unown问题修复 ([7b3b2ed](https://review.byted.org/#/q/7b3b2ed))
* UnreadCountNotice 接入chatterIds逻辑 ([b317831](https://review.byted.org/#/q/b317831))
* 两个loading不消失解决 ([ac8440c](https://review.byted.org/#/q/ac8440c))
* 使用自定义user-agent，network收敛 ([02342f5](https://review.byted.org/#/q/02342f5)), closes [#591](https://jira.bytedance.com/browse/LKI-591)
* 保存图片按钮增加点击态 ([755351e](https://review.byted.org/#/q/755351e))
* 修复Ding偶尔重复的问题 ([17972a9](https://review.byted.org/#/q/17972a9))
* 修复iOS9下alert闪退 ([e295127](https://review.byted.org/#/q/e295127))
* 修复post消息只有图片时分割线不显示的bug ([f1f6e7d](https://review.byted.org/#/q/f1f6e7d))
* 修复statusbar横屏、修复通过链接进入回话的错误文案 ([9d03c69](https://review.byted.org/#/q/9d03c69))
* 修复帖子@人attributedText point加错的bug ([d0784ac](https://review.byted.org/#/q/d0784ac))
* 修复引导页面位置错误问题 ([8ecf2e1](https://review.byted.org/#/q/8ecf2e1))
* 修复数据库升级问题 ([1c4f325](https://review.byted.org/#/q/1c4f325))
* 修复返回时gif消失的问题 ([e37c1d6](https://review.byted.org/#/q/e37c1d6))
* 修复键盘弹出遮盖问题 ([c5e3ad8](https://review.byted.org/#/q/c5e3ad8))
* 最后一条消息没有更新 ([fa68110](https://review.byted.org/#/q/fa68110))
* 单聊建群user顺序改变 ([e6450cb](https://review.byted.org/#/q/e6450cb))
* 单聊建群界面样式修改 ([0f0e2fd](https://review.byted.org/#/q/0f0e2fd))
* 去掉回复消息名字后面的"回复"样式 ([e0d2b32](https://review.byted.org/#/q/e0d2b32))
* 去除检查提交分支 ([e26be9e](https://review.byted.org/#/q/e26be9e))
* 在消息model中设置memberCount ([d009212](https://review.byted.org/#/q/d009212))
* 客服群默认关闭群设置 ([049adcc](https://review.byted.org/#/q/049adcc))
* 已读未读列表中，@所有人，不对每个人做@标记 ([1e69614](https://review.byted.org/#/q/1e69614))
* 数据库升级2没有renew db ([a857fff](https://review.byted.org/#/q/a857fff))
* 有的会话没有预览 ([6ff88dc](https://review.byted.org/#/q/6ff88dc)), closes [#582](https://jira.bytedance.com/browse/LKI-582)
* 消息全部已读仍然可以跳已读未读进列表 ([11fbd4d](https://review.byted.org/#/q/11fbd4d))
* 短回复消息，也出现查看全文 ([92fc5c7](https://review.byted.org/#/q/92fc5c7)), closes [#618](https://jira.bytedance.com/browse/LKI-618)
* 解决LKLabel textSize+1导致outOfRange判断逻辑出错的bug ([04d4337](https://review.byted.org/#/q/04d4337))
* 解决已读未读已发送就退出后已读未读label更新错误的问题 ([5c8147d](https://review.byted.org/#/q/5c8147d))
* 解决普通消息变ding消息unreadCount变更不及时问题 && 解决readStatusButton可能画不上的问题 ([176ae42](https://review.byted.org/#/q/176ae42))


### Features

*  选择消息加入数量限制 ([7e640f2](https://review.byted.org/#/q/7e640f2))
* add animation queue and guide UI component ([b7f337e](https://review.byted.org/#/q/b7f337e))
* add guide base view controller ([a04392a](https://review.byted.org/#/q/a04392a))
* add guide manager ([7d6c361](https://review.byted.org/#/q/7d6c361))
* add swipe cell && messagePicker 加入新消息提醒 ([0090155](https://review.byted.org/#/q/0090155))
* LKLabel @自己支持整体换行 ([0f1b225](https://review.byted.org/#/q/0f1b225)), closes [#631](https://jira.bytedance.com/browse/LKI-631)
* LKLabel支持UIView attachMent ([b287fdd](https://review.byted.org/#/q/b287fdd)), closes [#611](https://jira.bytedance.com/browse/LKI-611)
* message picker 加入读消息逻辑 ([0ab9c5c](https://review.byted.org/#/q/0ab9c5c))
* MessageMemberRef logic add ([d5a1a67](https://review.byted.org/#/q/d5a1a67)), closes [#614](https://jira.bytedance.com/browse/LKI-614)
* support changelog ([03112f7](https://review.byted.org/#/q/03112f7))
* update Kingfisher to 3.11.0 ([7e05f60](https://review.byted.org/#/q/7e05f60))
* 优化搜索高亮显示 ([b365406](https://review.byted.org/#/q/b365406))
* 使用富文本回复消息 ([6cebe4f](https://review.byted.org/#/q/6cebe4f))
* 保存图片到手机的UI优化 ([2dd5adf](https://review.byted.org/#/q/2dd5adf)), closes [#623](https://jira.bytedance.com/browse/LKI-623)
* 加急Cell样式修改 ([558f369](https://review.byted.org/#/q/558f369))
* 客服特化 ([49d3fd1](https://review.byted.org/#/q/49d3fd1)), closes [#602](https://jira.bytedance.com/browse/LKI-602)
* 已读未读详情页本地有数据不提示拉取失败 ([73ec8c9](https://review.byted.org/#/q/73ec8c9))
* 已读未读页显示优化 ([416e3d3](https://review.byted.org/#/q/416e3d3))
* 拨打电话系统消息改造 ([69dd74b](https://review.byted.org/#/q/69dd74b))
* 搜索未注册的往后排 ([fda6ce1](https://review.byted.org/#/q/fda6ce1))
* 支持系统外跳转到lark中的页面 ([9466d7f](https://review.byted.org/#/q/9466d7f)), closes [#589](https://jira.bytedance.com/browse/LKI-589)
* 支持识别图片中的二维码 ([cba497c](https://review.byted.org/#/q/cba497c))
* 添加了两个引导页面的代码 ([0b1155b](https://review.byted.org/#/q/0b1155b))
* 设置帮助与反馈文案修改 ([47ef2ff](https://review.byted.org/#/q/47ef2ff))
* 重做已读/未读详情页 ([3b7c155](https://review.byted.org/#/q/3b7c155))
* 阅读详情页预先拉取本地数据 ([b4a890b](https://review.byted.org/#/q/b4a890b))



<a name="1.1.0"></a>
# 1.1.0 (2017-08-08)



<a name="1.0.0"></a>
# 1.0.0 (2017-07-19)



<a name="1.0.0-beta3"></a>
# 1.0.0-beta3 (2017-07-16)



<a name="1.0.0-beta2"></a>
# 1.0.0-beta2 (2017-07-14)



<a name="1.0.0-beta1"></a>
# 1.0.0-beta1 (2017-07-11)



<a name="0.11.6"></a>
## 0.11.6 (2017-06-28)



<a name="0.11.5"></a>
## 0.11.5 (2017-06-21)



<a name="0.11.3-real"></a>
## 0.11.3-real (2017-06-09)



<a name="0.11.3"></a>
## 0.11.3 (2017-06-09)



<a name="0.11.0-real"></a>
# 0.11.0-real (2017-05-27)



<a name="0.11.0"></a>
# 0.11.0 (2017-05-27)



<a name="0.10.4"></a>
## 0.10.4 (2017-05-19)



<a name="0.10.3"></a>
## 0.10.3 (2017-05-18)



<a name="0.10.2"></a>
## 0.10.2 (2017-05-08)



<a name="0.10.1"></a>
## 0.10.1 (2017-05-05)



<a name="0.10.0"></a>
# 0.10.0 (2017-05-03)



<a name="0.9.10"></a>
## 0.9.10 (2017-04-28)



<a name="0.9.9"></a>
## 0.9.9 (2017-04-27)



<a name="0.9.8"></a>
## 0.9.8 (2017-04-26)



<a name="0.9.7"></a>
## 0.9.7 (2017-04-25)



<a name="0.9.6"></a>
## 0.9.6 (2017-04-24)



<a name="0.9.5"></a>
## 0.9.5 (2017-04-21)



<a name="0.9.4"></a>
## 0.9.4 (2017-04-20)



<a name="0.9.3"></a>
## 0.9.3 (2017-04-19)



<a name="0.9.2"></a>
## 0.9.2 (2017-04-18)



<a name="0.9.1"></a>
## 0.9.1 (2017-04-17)



<a name="0.9.0"></a>
# 0.9.0 (2017-04-14)



<a name="0.8.5"></a>
## 0.8.5 (2017-04-13)



