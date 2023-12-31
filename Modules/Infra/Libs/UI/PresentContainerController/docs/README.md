## PresentContainerController

## 功能
从各个方向 present vc, 支持 addsubview 和 present 两种方式
## 使用

~~~
let present1 = DatasourceItem(title: "Present from top") {
    let subView = SubViewController()
    let wrapper = PresentWrapperController(
    subView: subView,
    subViewSize: CGSize(width: UIScreen.main.bounds.width, height: 200))
    let container = PresentContainerController(subViewController: wrapper, animate: PresentFromTop())
    self.present(container, animated: false, completion: nil)
}

let add1 = DatasourceItem(title: "Add subview from top") {
    let subView = Sub2ViewController()
    let container = PresentContainerController(subViewController: subView, animate: PresentFromTop())
    container.show(in: self)
}
~~~

## 注意事项
subViewController 必须是有宽高约束的，如果没有相应约束 请使用 PresentWrapperController 包装一层
