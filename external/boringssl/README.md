boringssl ios pod 库， 直接引入pod file 即可。

// 版本说明（ChangeLog）
2020.05.06  最新版本是0.1.4，在0.1.3的基础上支持bitcode
2020.04.13  最新版本是0.1.3，在0.1.2的基础上添加了遗漏的文件libboringssl_asm.a
2019.12.29  最新版本是0.1.2，本次改动是一个全新升级，包含了支持TLSv1.3等更新


//依赖方法

source 'git@code.byted.org:TTIOS/tt_pods_specs.git'

pod 'boringssl', '0.0.7'
