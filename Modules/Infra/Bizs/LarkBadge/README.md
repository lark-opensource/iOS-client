# LarkBadge

## 组件作用
统一Lark中的Badge
doc: https://bytedance.feishu.cn/space/doc/doccntInJUUGkFrVlJhmf0


## 使用方法

1. observe
`
view.badge.observePath(Path().a.b.c.d) // 监听 .a, .b, .c, .d 路径
view.badge.combinePath(Path().e.f)         // 关联 .e, .f 路径
`

2. config
`
view.badge.setType(.dot)
view.badge.setOffset(CGPoint(x: -30, y: -30))
`
3.setBadge
`
 BadgeManager.setBadge(Path().a.b.c.d, type: .label(.number(1)))
`

4. clearBadge
`
view.badge.clearBadge() // 直接操作View
BadgeManager.clearBadge(Path().a.b.c.d) // 全局通过path操作Viwe
`

## Author
