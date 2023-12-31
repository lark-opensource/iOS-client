# MobileCV2-SDK

相关文档可查看[这里](https://wiki.bytedance.net/pages/viewpage.action?pageId=145996099)

### 说明
release 是相对稳定的分支，用于发布的版本会打 `tag`.

### Change logs
- 2018.1.3 [1.0.0] 第一个稳定版本
- 2018.1.7 [1.0.1] solvepnp 函数增加 epnp 求解方式
- 2018.1.7 [1.0.2] podspec, SDK 拉取方式从 https 改成 git, 源码无修改
- 2018.2.6 [1.0.3] 优化sobel, pyrdown, warpPerspective函数，修改验证结果方式，注释reduce的crash问题
- 2018.4.15 增加flann, features2d两个模块，并增加Eigen的支持
- 2018.4.23 去掉 tt_FAST 函数，修复 iOS 编译没把 xfeatures2d 编进来的 bug
- 2018.4.24 dis光流修改线程个数
- 2018.4.24 [1.0.4] tag升级到1.0.4
- 2018.6.6 优化resize的8uc3的NN性能， resize 8uc1和8uc4的性能，ios的resize性能对齐Android性能。优化tt_warpAffine的性能。
- 2018.6.15 用platform=14的方式编
- 2018.6.15 [1.0.6] tag up to 1.0.6
- 2018.6.21 优化calcOpticalFlowPyrLK
- 2018.6.29 优化resize 8uc3
- 2018.7.2 ios, rollback tt_warp crash
- 2018.7.18 添加版本号，优化 fast, fix bugs
- 2018.10.30 增加inpaint支持，优化NS参数的inpaint
- 2019.03.17 修正inpaint在某些情况下内存访问越界的错误。
- 2019.03.22 继续修正inpaint在某些情况下内存访问越界的错误。
- 2019.10.21 导出composeRT
- 2019.11.11 支持CV_BGR2HSV，部分Mat函数去掉inline
- 2020.03.01 导出Subdiv2D, 修复部分全局变量与opencv冲突的问题。使用opencv3.4的多线程调度方式，提升多线程性能。优化boxfilter，reduce和EqualizeHist的性能。
- 2020.05.07 增加SIFT，AKAZA和seamlessClone的实现，优化seamlessClone，优化boxfilter u8c1，修正DISflow小分辨率图片crash问题
- 2020.06.09 增加RGB2YUV，AMFilter，circle，fillPoly支持
- 2020.07.07 更换编译参数为Oz
- 2020.08.11 增加goodFeaturesToTrack
- 2021.09.22 [1.8.8] 增加ap3p，PC端支持AVX2
- 2021.10.12 [1.8.9] 修复 avx 运行crash
- 2021.10.13 [1.9.0] 修复mac和ios bach模块符号找不到的问题
- 2021.10.13 [1.9.1] 设置mac osx target 最小版本为10.9【废弃版本】
- 2021.10.13 [1.8.11] 设置mac osx target 最小版本为10.9
- 2021.12.20 [1.8.13] emsdk 2.0.22
- 2021.12.27 [1.8.14] emsdk 1.40.1、修复光流横屏问题
- 2022.01.20 [1.8.15] 修复移动端resize线上crash问题
- 2022.03.23 [1.8.16] 优化pc端cpu性能，boxfilter(3x3、5x5、11x11)，resize，lut_win，addWeight
- 2022.03.23 [1.8.17] wasm更新emsdk 2.0.22
- 2022.07.19 [1.8.18] mobilecv 暴露符号
- 2022.08.04 [1.8.19] 修复ios端x86不支持
- 2022.10.25 [1.8.20] 修复pc端光流crash问题
- 2023.02.03 [1.8.25] 修复resize neon和avx优化crash，RTC光流添加内存访问保护
- 2023.03.23 [1.8.27] 修复resize neon 实现中offset为short类型导致的类型溢出崩溃
