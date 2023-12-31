//
//  AppDelegate.swift
//  Lark
//
//  Created by 董朝 on 2018/8/28.
//  Copyright © 2018年 com.bytedance.xx. All rights reserved.
//
import Foundation
import UIKit
import LarkSplitViewController
import LarkTraitCollection
import LKLoadable

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        LKLoadableManager.run(LoadableState(rawValue: 0))
        LKLoadableManager.run(LoadableState(rawValue: 1))
        LKLoadableManager.run(LoadableState(rawValue: 2))

        RootTraitCollection.shared.useCustomSizeClass = true

        self.window = UIWindow()
        let masterVC = Master()

        let split = LKSplitViewController.default(
            with: masterVC,
            wrap: UINavigationController.self,
            defaultVCProvider: { () -> DefaultVCResult in
                return DefaultVCResult(defaultVC: Default())
            }
        )
        // 先设置detail，再设置displayMode。否则，会展示allvisible。
        // 因为masterFullScreen检测到有detail的设置，会想展示detail，从而转变displayMode为allvisible
        split.preferredDisplayMode(.masterFullscreen, animated: true)
        self.window?.rootViewController = split
        self.window?.rootViewController?.view.backgroundColor = .white
        self.window?.makeKeyAndVisible()
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        NSLog("application will terminate")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        NSLog("enter backgroud")
    }

}

class Master: UIViewController {
    let mn = MasterNext()
    override func viewDidLoad() {
        super.viewDidLoad()
        // 添加背景图
        let imageView = UIImageView(image: UIImage(named: "moon.jpg"))
        self.view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 添加按钮，变化displayMode：masterFullScreen -> allVisible
        let btn = UIButton()
        btn.backgroundColor = .green
        self.view.addSubview(btn)
        btn.frame = CGRect(x: 100, y: 100, width: 200, height: 44)
        btn.setTitle("设置displayMode", for: .normal)
        btn.addTarget(self, action: #selector(click), for: .touchUpInside)

        // 添加按钮，push到下一个页面
        let btn2 = UIButton()
        btn2.backgroundColor = .green
        self.view.addSubview(btn2)
        btn2.frame = CGRect(x: 100, y: 200, width: 200, height: 44)
        btn2.setTitle("push下一个页面", for: .normal)
        btn2.addTarget(self, action: #selector(click2), for: .touchUpInside)
    }

    @objc
    func click() {
        let masterNext = MasterNext()
        if let split = self.customLKSplitViewController {
            // 变化完displayMode后，再push下一个页面
            split.preferredDisplayMode(.allVisible, animated: true, completion: { [weak self] in
                self?.navigationController?.pushViewController(masterNext, animated: true)
            })
        }
    }

    @objc
    func click2() {
        let masterNext = MasterNext()
        self.navigationController?.pushViewController(masterNext, animated: true)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        print("-------------- master size \(size)")
    }
}

class MasterNext: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // 添加背景图
        let imageView = UIImageView(image: UIImage(named: "word.jpg"))
        self.view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 添加按钮，回到masterFullScreen的样式
        let button = UIButton()
        self.view.addSubview(button)
        button.setTitle("close", for: .normal)
        button.frame = CGRect(x: 100, y: 200, width: 200, height: 100)
        button.addTarget(self, action: #selector(click), for: .touchUpInside)

        // 设置detail页面
        let button2 = UIButton()
        self.view.addSubview(button2)
        button2.setTitle("set detail", for: .normal)
        button2.frame = CGRect(x: 100, y: 400, width: 200, height: 100)
        button2.addTarget(self, action: #selector(click2), for: .touchUpInside)
    }

    @objc
    func click() {
        // 设置detail为default页面，并返回masterFullScreen
        self.customSplitViewController?.showDetailViewController(Default(), sender: nil)
        if let split = self.customLKSplitViewController {
            split.preferredDisplayMode(.masterFullscreen, animated: true)
        }
        // master页面pop，并关闭动画
        self.navigationController?.popViewController(animated: false)
    }

    @objc
    func click2() {
        let detail = Detail()
        detail.supportFullScreenInDetail = true
        detail.autoAddFullScreenItem = true
        detail.supportFullScreenGesture = true
        self.customSplitViewController?.showDetailViewController(UINavigationController(rootViewController: detail), sender: nil)
    }
}

class Detail: UIViewController {
    // fullScreenIcon按钮的使用方法
    lazy var fullScreenIcon = FullScreenIcon(vc: self)
    override func splitDisplayModeChange(displayMode: LKSplitViewController.DisplayMode) {
        updateItem()
    }
    func updateItem() {
        if let split = self.customSplitViewController {
            if split.displayMode == .allVisible {
                self.fullScreenIcon.updateIcon()
            } else if split.displayMode == .detailFullscreen {
                self.fullScreenIcon.updateIcon()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.blue
        let imageView = UIImageView(image: UIImage(named: "cloud.jpg"))
        self.view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.view.addSubview(fullScreenIcon)
        fullScreenIcon.frame = CGRect(x: 400, y: 100, width: 50, height: 50)

        let btn = UIButton()
        btn.backgroundColor = UIColor.black
        btn.setTitle("下一页", for: .normal)
        self.view.addSubview(btn)
        btn.frame = CGRect(x: 100, y: 100, width: 200, height: 44)
        btn.addTarget(self, action: #selector(click), for: .touchUpInside)

        let btn2 = UIButton()
        btn2.backgroundColor = UIColor.black
        btn2.setTitle("allVisible", for: .normal)
        self.view.addSubview(btn2)
        btn2.frame = CGRect(x: 100, y: 200, width: 200, height: 44)
        btn2.addTarget(self, action: #selector(click2), for: .touchUpInside)

        let btn3 = UIButton()
        btn3.backgroundColor = UIColor.black
        btn3.setTitle("masterFullscreen", for: .normal)
        self.view.addSubview(btn3)
        btn3.frame = CGRect(x: 100, y: 300, width: 200, height: 44)
        btn3.addTarget(self, action: #selector(click3), for: .touchUpInside)

        let btn4 = UIButton()
        btn4.backgroundColor = UIColor.black
        btn4.setTitle("detailOverlay", for: .normal)
        self.view.addSubview(btn4)
        btn4.frame = CGRect(x: 100, y: 400, width: 200, height: 44)
        btn4.addTarget(self, action: #selector(click4), for: .touchUpInside)

        let btn5 = UIButton()
        btn5.backgroundColor = UIColor.black
        btn5.setTitle("masterOverlay", for: .normal)
        self.view.addSubview(btn5)
        btn5.frame = CGRect(x: 100, y: 500, width: 200, height: 44)
        btn5.addTarget(self, action: #selector(click5), for: .touchUpInside)

        NotificationCenter.default.addObserver(
            forName: LKSplitViewController.DisplayModeChange,
            object: nil,
            queue: nil) { (noti: Notification) in
            print("receive notification \(noti.object)")
        }
    }

    @objc
    func click() {
        let detail = Detail()
        detail.supportFullScreenInDetail = true
        detail.supportFullScreenGesture = true
        detail.autoAddFullScreenItem = true
        detail.view.backgroundColor = .white
        let text = UITextField()
        text.frame = CGRect(100, 350, 100, 30)
        text.backgroundColor = .cyan
        detail.view.addSubview(text)
        self.navigationController?.pushViewController(detail, animated: true)
    }

    @objc
    func click2() {
        if let split = self.customLKSplitViewController {
            split.preferredDisplayMode(.allVisible, animated: true)
        }
    }

    @objc
    func click3() {
        if let split = self.customLKSplitViewController {
            split.preferredDisplayMode(.masterFullscreen, animated: true)
        }
    }

    @objc
    func click4() {
        if let split = self.customLKSplitViewController {
            split.preferredDisplayMode(.detailOverlay, animated: true)
        }
    }

    @objc
    func click5() {
        if let split = self.customLKSplitViewController {
            split.preferredDisplayMode(.masterOverlay, animated: true)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        print("-------------- detail size \(size)")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("detail viewDidAppear")
    }

    override func removeFromParent() {
        super.removeFromParent()
    }

    override func splitVCDisplayModeChange(split: LKSplitViewController) {
        print("splitVCDisplayModeChange")
    }
}

class Default: UIViewController, DefaultDetailVC {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "this is default detail"
        self.view.backgroundColor = UIColor.green
        let imageView = UIImageView(image: UIImage(named: "tower.jpg"))
        self.view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
