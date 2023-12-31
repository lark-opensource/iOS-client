# LarkZoomable

## 组件作用
支持界面缩放，根据当前缩放等级动态返回字体和约束。

## 使用方法
使用字体
```swift
/// Before
label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
/// After
label.font = UIFont.body1
```
添加约束
```swift
/// Before
avatarView.snp.makeConstraints { make in
   make.size.equalTo(20)
}
/// After
avatarView.snp.makeConstraints { make in
   make.size.equalTo(20.auto())
}
```

详见：[Lark iOS 字体缩放接入指南](https://bytedance.feishu.cn/docs/doccnM1jwtgWfYy7hn3sOhL5dVf)

## Author
王海栋（wanghaidong.nku@bytedance.com）
