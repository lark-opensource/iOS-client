# Owner 配置脚本测试目录

这个目录用于存放 Owner 配置脚本相关的测试

## 目录概述

- `mock/`: mock 数据相关文件
  - `empty_config.yml`: 空的配置文件
  - `invalid_yaml_format.yml`: 错误的YAML格式
  - `test_for_add_pod_expect.yml`: 用于测试 add_pod! 的结果对比
  - `test_for_add_pod_template.yml`: 用于生成 add_pod! 的目标文件

- `config_spec.rb`: 测试 OwnerConfig 的解析
- `spec_helper.rb`: 单测覆盖率、全局依赖等配置
