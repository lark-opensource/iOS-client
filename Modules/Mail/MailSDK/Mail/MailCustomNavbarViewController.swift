//  Created by weidong fu on 5/12/2017.

/*!
 所有ViewController应当继承本类
 负责统一处理大小自定义导航样式
 提供默认返回按钮
 提供默认Loading(存疑)
 */

import Foundation

class MailCustomNavbarViewController: MailBaseViewController {
    var observeIsInited = false
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    final lazy var customNavigationBar: MailNavigationBar = {
        let nav = MailNavigationBar(frame: .zero)
        nav.isNeedHideArrow = true
        return nav
    }()

    private lazy var leftBarButtonItemObserve: NSKeyValueObservation? = {
        return self.navigationItem.observe(\UINavigationItem.leftBarButtonItem, options: .new, changeHandler: { [weak self] (_, value) in
            var item = value.newValue as? UIBarButtonItem
            var items: [UIBarButtonItem]
            if let obj = item { items = [obj] } else { items = [] }
            self?.customNavigationBar.setLefthtBarButtons(items: items)
            MailCustomNavbarViewController.asjustLeftBarButtonItems(items: &items)
            if self?.tabBarController != nil {
                self?.tabBarController?.navigationItem.leftBarButtonItem = item
            }
        })
    }()
    private lazy var leftBarButtonItemsObserve: NSKeyValueObservation? = {
        return self.navigationItem.observe(\UINavigationItem.leftBarButtonItems, options: .new, changeHandler: { [weak self] (_, value) in
            var items = value.newValue as? [UIBarButtonItem] ?? []
            self?.customNavigationBar.setLefthtBarButtons(items: items)
            MailCustomNavbarViewController.asjustLeftBarButtonItems(items: &items)
            if self?.tabBarController != nil {
                self?.tabBarController?.navigationItem.leftBarButtonItems = items
            }
        })
    }()
    private lazy var rightBarButtonItemObserve: NSKeyValueObservation? = {
        return self.navigationItem.observe(\UINavigationItem.rightBarButtonItem, options: .new, changeHandler: { [weak self] (_, value) in
            var item = value.newValue as? UIBarButtonItem
            var items: [UIBarButtonItem]
            if let obj = item { items = [obj] } else { items = [] }
            self?.customNavigationBar.setRightBarButtons(items: items)
            MailCustomNavbarViewController.asjustRightBarButtonItems(items: &items)
            if self?.tabBarController != nil {
                self?.tabBarController?.navigationItem.rightBarButtonItem = item
            }
        })
    }()
    private lazy var rightBarButtonItemsObserve: NSKeyValueObservation? = {
        return self.navigationItem.observe(\UINavigationItem.rightBarButtonItems, options: .new, changeHandler: { [weak self] (_, value) in
            var items = value.newValue as? [UIBarButtonItem] ?? []
            self?.customNavigationBar.setRightBarButtons(items: items)
            MailCustomNavbarViewController.asjustRightBarButtonItems(items: &items)
            if self?.tabBarController != nil {
                self?.tabBarController?.navigationItem.rightBarButtonItems = items
            }
        })
    }()

    private class BaseView: UIView {
        override func addSubview(_ view: UIView) {
            super.addSubview(view)
            if let bar = self.subviews.first(where: { $0 is MailNavigationBar }) {
                self.bringSubviewToFront(bar)
            }
        }
    }

    open override func loadView() {
        _ = self.leftBarButtonItemObserve
        _ = self.leftBarButtonItemsObserve
        _ = self.rightBarButtonItemObserve
        _ = self.rightBarButtonItemsObserve
        observeIsInited = true

        view = BaseView(frame: UIScreen.main.bounds)
        view.addSubview(self.customNavigationBar)
//        waterMarkConfig.view.map {
//            view.addSubview($0)
//            $0.layer.zPosition = CGFloat.greatestFiniteMagnitude
//            $0.snp.makeConstraints({ (make) in
//                make.edges.equalToSuperview()
//            })
//        }
        customNavigationBar.snp.makeConstraints({ (make) in
            make.top.equalTo(Display.topSafeAreaHeight)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(self.customNavigationBar.preferedHeight)
        })
        customNavigationBar.blurView.snp.updateConstraints({ (make) in
            make.top.equalToSuperview().offset(-UIApplication.shared.statusBarFrame.height)
        })

        view.backgroundColor = UIColor.ud.bgBody
        let backBarButtonItem = UIBarButtonItem(image: I18n.image(named: "navigation_back"),
                                                style: .plain,
                                                target: self,
                                                action: #selector(backBarButtonItemAction(sender:)))
        backBarButtonItem.tintColor = UIColor(red: 0.07, green: 0.12, blue: 0.18, alpha: 1.00)
        navigationItem.leftBarButtonItem = backBarButtonItem
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.isNavigationBarHidden = true
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hideLoading()
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @objc
    open func backBarButtonItemAction(sender: UIBarButtonItem) {
        back()
    }

    func back() {
        if let navi = self.navigationController {
            if navi.viewControllers.count > 1 {
                navi.popViewController(animated: true)
            } else {
                navi.dismiss(animated: true, completion: nil)
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    private class func asjustLeftBarButtonItems(items: inout [UIBarButtonItem]) {
        for index in 0..<items.count {
            let offset = CGFloat(index + 1) * -8
            items[index].imageInsets = UIEdgeInsets(top: 0, left: offset, bottom: 0, right: -offset)
            if items[index].tintColor == nil {
                items[index].tintColor = UIColor(red: 0.07, green: 0.12, blue: 0.18, alpha: 1.00)
            }
        }
    }
    private class func asjustRightBarButtonItems(items: inout [UIBarButtonItem]) {
        for index in 0..<items.count {
            let offset = CGFloat(index + 1) * 8
            items[index].imageInsets = UIEdgeInsets(top: 0, left: offset, bottom: 0, right: -offset)
            if items[index].tintColor == nil {
                items[index].tintColor = UIColor(red: 0.07, green: 0.12, blue: 0.18, alpha: 1.00)
            }
        }
    }

    open override var shouldAutorotate: Bool {
        return false
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
