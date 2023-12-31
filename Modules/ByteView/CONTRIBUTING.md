贡献规则
========
本人假设你已经拥有本仓库的访问权限。如果需要权限请联系管理员。

## 基本开发流程
### 使用
master 分支上任意提交，或者被打了tag的提交，均被认为是稳定版本，可以直接使用。

### 开发、提交代码

1. 请确保checkout develop分支的最新提交。 如果代码修改并不是基于develop 分支的最新提交，请rebase。
2. 创建一个临时分支（分支名称可以参考下面分支说明中的建议，例如：MR/1234），将修改内容提交到该临时分支。
3. 创建一个Merge Request（从临时分支到develop），参照 Merge Request说明，填写相应参数。
4. 通知管理员成员、或其他人员进行 code review。
5. 满足merge条件后（CI、code review）合并修改进入develop，并删除临时分支。

### 版本发布流程（管理员）

1. 在develop中找到要发布的基线，check out 一个release 分支。以版本号命名。
2. 更新change log 到该分支（与上一版本的差异）
3. 发布内测版本进行验收。
4. 若验收发现严重问题，则删除该release分支，发布版本失败。待修复后重新步骤1。
5. 若验收中发现部分问题，则可以提交快速修改 或者 接收新的Merge request。同时cherry pick 回 develop 分支。
6. 若验收通过，则按release 模板提交merge request到Master。并且同时cherry pick 回 develop 分支。
7. Master分支merge 相应的merge request之后，需要打上相应的tag，代表归档。



##分支说明

### 常驻分支
* master：  归档分支，默认分支，受保护分支
* develop： 开发分支，受保护分支

**开发人员不应该向master分支发起 merge request。新功能以及bugfix等修改，需要现象这个分支发起merge reqeust，code review 通过后合入。 非管理员向master发起的merge request将会被直接拒绝。**

### 临时分支
* Release/0.1.0 预发布分支，受保护分支

发布前，管理员从指定提交处创建。可以销毁重新创建。管理员可以直接提交quickfix。
发布版本时，该分支会想master & develop 两个分支同时提交MR，并删除。

master分支每个mr合并后需要打一个新的tag。

### 其他建议

* 建议以目的为开头创建分支名。 例如 新功能 login分支名为 Feature/login、 其他： Bugfix/issue-2015、Enhance/gitlab-ci等等
* 本地创建merge request 请以 MR/xxxx 为开头。

## Merge Request 填写规范

### 标题规范
* 标题应使用一句话描述Merge Request，不超过20个字。
* 标题不要包含 jira issue号码等其他关联信息。
* 标题要有明确的含义，能够完全表示Merge Request 修改中所代表含义
* 标题应仅包含一个块完整的内容，如果发现无法用一句话描述清楚这个Merge Request，则有可能你需要将其拆分为多个merge Request进行合并。

标题有可能被用于生成 Change Log

### 描述规范

描述至少要包含以下两方面内容

* 该Merge Request做了那些修改，目的是什么？
* 相关联的问题（可被close的问题）

### Label规范

Label用于自动生成Change Log， 主要包含以下：

* Feature: 添加功能的代码修改。 会记录到change log中。
* BugFix:  修复bug的代码修改。 会记录到change log 中。
* Documentation: 文档的修改。
* Enhancement: 重构、增加自动化测试、提升性能等无关功能的代码修改。
* Configuration: 配置CI、build系统、部署系统。或者其他无关代码和功能的修改。

### commit 建议
* 不需要以特殊的模式填写comments
* 尽量将小而独立的代码修改提交
* comments内容要清晰而具体

## 工具

TBD 