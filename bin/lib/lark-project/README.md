# Lark::Project

云文档相关介绍：https://bytedance.feishu.cn/wiki/wikcnsTdFAz4Tnl0pvCoquDF2uc

这个插件存放Lark平台工程相关可复用的代码和配置, 保证在各单品环境的一致性，简化子工程环境的配置复杂性。

工程和平台通用的环境配置，脚本代码，可以写入这个gem中发布同步

修改之后，可以使用`rake push[branch]`发布到[镜像仓库对应分支](https://code.byted.org/lark/ios-lark-project-mirror),
branch默认为当前分支名
然后在子工程gemfile中通过git更新到对应配置

镜像仓库只做备份和同步代码用，代码修改应该到ios-client工程bin/lib/lark-project目录下修改后，手动同步

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'lark-project', git: 'git@code.byted.org:lark/ios-lark-project-mirror.git', branch: 'develop'
# 或者使用commit
# gem 'lark-project', git: 'git@code.byted.org:lark/ios-lark-project-mirror.git', ref: 'sha'
```

And then execute:

    $ bundle install

Or update branch commit

    $ bundle update

## Usage
目前该项目主要有两个文件：

lib/lark/project/environment.rb
负责环境变量的定义，以及一些通用的配置参数(这些参数可能被子工程修改自定义), 环境对象通过`$lark_env`全局使用

lib/lark/project/podfile_mixin.rb
这个文件是Podfile扩展和配置的入口, 需要在Podfile中，`require 'lark/project/podfile_mixin'`。这个文件主要存放扩展方法，和模版配置，方便子工程复用



## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Lark::Project project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/lark-project/blob/main/CODE_OF_CONDUCT.md).
