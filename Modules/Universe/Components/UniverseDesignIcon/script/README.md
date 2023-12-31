## 需要知道的一些文件介绍

## 启动

### FetchIcon.rb
```bash
# 可前往 https://bnpm.bytedance.net/package/@universe-design/icons 查看呢最新版本号

# 最后的 1.241.0 为本次图标更新的参数
ruby FetchIcon.rb 1.241.0
```

## 一些配置文件
### block_list.csv
图标更新黑名单，此文件中的图标会在资源下载完后，直接删除

### icon_pa_white_list.csv
icon_pa- 系列图标白名单，正常情况下，移动端打包都不会携带 icon_pa- 为前缀的图标，但是 现在VC业务依赖其中的图标，于是创建该文件用来专门处理 icon_pa- 系列中的白名单图标。正常该系列图标在资源下载完后，也应该被删除。现在将会保留白名单中的图标

### SpecialSize.csv
图标尺寸定制。可能有业务存在需要高清大图标的要求，现在的图标生成的png的尺寸不够，则可以在此文件中指定某图标对应的尺寸大小

### compress_png.py
png 图片压缩脚本

### iconFontSetting.rb
iconFont 中存在一些图标的 svg 绘制不规范的问题，因此生成的 iconFont 效果并不好。因此本文件中的图标将保留 svg 转 png，而不会转换为 iconfont

