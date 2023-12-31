# Owner 配置脚本目录

这个目录用于存放 Owner 配置相关的脚本

[Owner 信息本地化配置](https://bytedance.feishu.cn/wiki/TiJTwR6jcihJpikOMHMcGgIPnxdn)

## 目录概述

- `lib/`: 提供给其他脚本使用的库文件
- `lib/config.rb`: 定义 Owner 配置的数据结构
- `lib/validate.rb`: 校验仓库中的配置是否合法
- `lib/utils.rb`: 校验仓库中的配置是否合法


- `get_owner_info.rb`: 数据消费脚本，用于 CI Job [飞书Owner信息防劣化检查](https://bits.bytedance.net/devops/1500033282/pipeline/marketplace/compile/edit?appId=137801&configId=39625&devops_space_type=client&type=debug)


- `spec/`: 单测相关脚本


- `owner.rbs`: 存放类成员、方法等的类型信息，用于辅助 IDE 进行类型提示
