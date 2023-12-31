# LarkTag

## 组件作用

统一Lark内Tag样式，支持同时设置多个Tag

## 使用方法

```

import LarkTag

// 用类型填充
let tag = TagView()

// 设置最多显示个数
tag.maxTagCount = 2

// 设置间距
tag.spacing = 6

view.addSubview(tag)

tag.setTags([.bot, .external])


// 暂时不公开自定义类型，避免滥用自定义增加未来维护成本
```


## Author

孔凯凯

kongkaikai@bytedance.com
