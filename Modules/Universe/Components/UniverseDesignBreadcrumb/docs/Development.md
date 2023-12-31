# UniverseDesignBreadcrumb

## 组件作用
面包屑是用户界面中的一种辅助导航，可以显示当前页面在层级架构中的位置，并能快速返回之前的页面。

## 设计文档
### 需求
[https://bytedance.feishu.cn/docs/doccnG4lwxM0v8wNwEhJZPJHXmd](https://bytedance.feishu.cn/docs/doccnG4lwxM0v8wNwEhJZPJHXmd)

### 方案
主要分为两个类UDBreadcrumbView和UDBreadcrumbItemView
#### UDBreadcrumbItemView
提供每一个title的View，由两部分组成：展示title的button和nextView

支持定义每个item的title和状态
```
setItem(title: String, hasNext: Bool, index: Int)
```
#### UDBreadcrumbView
面包屑View，需要支持以下两点

- 所有item组成路径正常展示
- 当路径超过页面宽度时，超出区域的会自动向左滚动。可滑动查看超出屏幕区域部分。

设计如下：
采用UIScrollView展示，支持可滑动
接口如下：

```
    /// 根据title创建itemViews
     public func setItems(itemTitles: [String])

    /// 根据titles增加items
    public func pushItemWithTitles(titles: [String])

    /// 删除掉最后几个items
    public func popLast(count: Int = 1) 

    /// 从index开始删除到最后一个
    public func popTo(index: Int)

    /// 更新某项item的字体颜色
    public func updateItem(at index: Int, color: UIColor)
```
提供可以直接滚动到scrollView最右边的方法

```
public func scrollToRight(delay: Double = 0.25)
```
采用代理实现自定义每一项的点击事件

```
/// 每一项的点击事件代理
public protocol UDBreadcrumbViewDelegate: AnyObject {
    func tapIndex(index: Int)
}

```
### 使用方法
想要在自己的视图中加一个面包屑View，如下使用：

```
        let titles = ["颜色", "样式", "图标", "颜色", "样式", "图标", "颜色", "样式", "图标"]
        breadcrumbView.backgroundColor = .white
        breadcrumbView.setItems(itemTitles: titles)
        breadcrumbView.delegate = self
        self.view.addSubview(breadcrumbView)
        breadcrumbView.snp.makeConstraints { (make) in
            make.top.equalTo(100)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
        }
```
设置每一个title的点击事件，需要遵守代理

```
extension ViewController: UDBreadcrumbViewDelegate {
    func tapIndex(index: Int) {
        if index == 0 {
            self.navigationController?.pushViewController(UniverseDesignColorVC(), animated: true)
        } else if index == 1 {
            self.navigationController?.pushViewController(UniverseDesignStyleVC(), animated: true)
        } else {
            self.navigationController?.pushViewController(UniverseDesignFontVC(), animated: true)
        }
    }
}
```
