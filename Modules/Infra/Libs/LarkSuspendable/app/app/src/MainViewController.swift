//
//  MainViewController.swift
//  LarkSuspendableDev
//
//  Created by bytedance on 2021/1/5.
//

import Foundation
import UIKit
import SnapKit
import LarkSuspendable
import EENavigator
import UniverseDesignColor
import UniverseDesignTheme

class MainViewController: UIViewController {

    var colors: [UIColor] = [
        .systemRed,
        .systemOrange,
        .systemYellow,
        .systemGreen,
        .systemBlue,
        .systemTeal,
        .systemPurple
    ]

    private var currentClientId: String = "1"

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.text = "打开页面"
        return label
    }()

    private func makeButton(tag: Int) -> UIButton {
        let button = UIButton()
        button.tag = tag
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(UIColor.ud.N1000, for: .normal)
        button.setTitle("\(tag)", for: .normal)
        button.backgroundColor = colors[tag % colors.count]
        button.addTarget(self, action: #selector(pushToDetailController(_:)), for: .touchUpInside)
        return button
    }

    private func makeButton(title: String, sel: Selector) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.backgroundColor = UIColor.ud.N300
        button.setTitleColor(UIColor.ud.N1000, for: .normal)
        button.addTarget(self, action: sel, for: .touchUpInside)
        return button
    }

    private func addButton(_ button: UIButton) {
        button.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        btnStackView.addArrangedSubview(button)
    }

    private func addButtonGroup(_ buttons: [UIButton]) {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        stack.snp.makeConstraints { make in
            make.height.equalTo(40)
        }
        for button in buttons {
            stack.addArrangedSubview(button)
        }
        btnStackView.addArrangedSubview(stack)
    }

    private lazy var coldButton: UIButton = {
        let button = UIButton()
        button.setTitle("冷恢复", for: .normal)
        button.setTitleColor(UIColor.ud.N100, for: .normal)
        button.backgroundColor = UIColor.ud.N900
        button.addTarget(self, action: #selector(pushColdStartController(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var warmButton: UIButton = {
        let button = UIButton()
        button.setTitle("热恢复", for: .normal)
        button.setTitleColor(UIColor.ud.N100, for: .normal)
        button.backgroundColor = UIColor.ud.N900
        button.addTarget(self, action: #selector(pushWarmStartController(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var uniqieButton: UIButton = {
        let button = UIButton()
        button.setTitle("区分来源", for: .normal)
        button.setTitleColor(UIColor.ud.N100, for: .normal)
        button.backgroundColor = UIColor.ud.N900
        button.addTarget(self, action: #selector(pushUniqueController(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var vcStackView1: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var vcStackView2: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var btnStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        return stack
    }()

    private lazy var addVideoButton: UIButton = {
        let button = makeButton(title: "开始视频通话", sel: #selector(addCustomView))
        return button
    }()

    private lazy var removeVideoButton: UIButton = {
        let button = makeButton(title: "结束视频通话", sel: #selector(removeCustomView))
        return button
    }()

    private lazy var addIconButton: UIButton = {
        let button = makeButton(title: "添加RVC", sel: #selector(addRVCView))
        return button
    }()

    private lazy var removeIconButton: UIButton = {
        let button = makeButton(title: "移除RVC", sel: #selector(removeRVCView))
        return button
    }()

    private lazy var addLiveButton: UIButton = {
        let button = makeButton(title: "开启直播", sel: #selector(addLiveView))
        return button
    }()

    private lazy var removeLiveButton: UIButton = {
        let button = makeButton(title: "结束直播", sel: #selector(removeLiveView))
        return button
    }()

    private lazy var conflictButton: UIButton = {
        let button = makeButton(title: "添加互斥窗口", sel: #selector(addflectArea))
        return button
    }()

    private lazy var logoutButton: UIButton = {
        let button = makeButton(title: "当前账号\(currentClientId)（点击切换）", sel: #selector(changeClient(_:)))
        return button
    }()

    private lazy var addWatermarkButton = makeButton(
        title: "添加/更新水印",
        sel: #selector(updateWatermark(_:))
    )

    private lazy var removeWaterMarkButton = makeButton(
        title: "删除水印",
        sel: #selector(removeWatermark(_:))
    )

    private lazy var customView = VideoView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "多任务浮窗Demo"

        #if swift(>=5.5)
        if #available(iOS 15, *) {
            if let appearance = navigationController?.navigationBar.standardAppearance.copy() {
                appearance.backgroundColor = UIColor.white
                navigationController?.navigationBar.standardAppearance = appearance
                navigationController?.navigationBar.scrollEdgeAppearance = appearance
            }
        }
        #endif

        // 加载账号 1 配置（模拟 idle 启动加载延迟）
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            SuspendManager.shared.loadSuspendConfig(forClientId: self.currentClientId)
        }

        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(titleLabel)
        view.addSubview(vcStackView1)
        view.addSubview(vcStackView2)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
        }
        vcStackView1.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.height.equalTo(40)
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
        }
        vcStackView2.snp.makeConstraints { make in
            make.leading.trailing.height.equalTo(vcStackView1)
            make.height.equalTo(40)
            make.top.equalTo(vcStackView1.snp.bottom).offset(10)
        }
        for i in 0..<7 {
            vcStackView1.addArrangedSubview(makeButton(tag: i))
        }
        vcStackView2.addArrangedSubview(coldButton)
        vcStackView2.addArrangedSubview(warmButton)
        vcStackView2.addArrangedSubview(uniqieButton)

        view.addSubview(btnStackView)
        btnStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }

        addButtonGroup([showOrHideButton, darkModeButton])
        addButton(logoutButton)
        addButton(conflictButton)
        addButtonGroup([addIconButton, removeIconButton])
        addButtonGroup([addVideoButton, removeVideoButton])
        addButtonGroup([addLiveButton, removeLiveButton])
        addButtonGroup([addWatermarkButton, removeWaterMarkButton])
    }

    private lazy var showOrHideButton: UIButton = {
        let button = makeButton(title: "显示/隐藏浮窗", sel: #selector(showOrHideWindow))
        return button
    }()

    private lazy var darkModeButton: UIButton = {
        let title: String = {
            if #available(iOS 13.0, *) {
                switch UDThemeManager.userInterfaceStyle {
                case .light:    return "亮色模式"
                case .dark:     return "暗色模式"
                default:        return "跟随系统"
                }
            } else {
                return "暗色模式（无效）"
            }
        }()
        let button = makeButton(title: title, sel: #selector(switchDarkMode(_:)))
        return button
    }()

    @objc
    private func showOrHideWindow() {
        isSuspendWindowHidden.toggle()
        SuspendManager.shared.setSuspendWindowHidden(isSuspendWindowHidden)
    }

    @objc
    private func switchDarkMode(_ sender: UIButton) {
        if #available(iOS 13.0, *) {
            let next = UIUserInterfaceStyle(rawValue: (UDThemeManager.userInterfaceStyle.rawValue + 1) % 3)!
            UDThemeManager.setUserInterfaceStyle(next)
            let title: String = {
                switch UDThemeManager.userInterfaceStyle {
                case .light:    return "亮色模式"
                case .dark:     return "暗色模式"
                default:        return "跟随系统"
                }
            }()
            sender.setTitle(title, for: .normal)
        }
    }

    private var isSuspendWindowHidden: Bool = false

}

// MARK: - 打开页面

extension MainViewController {

    @objc
    private func pushToDetailController(_ sender: UIButton) {
        let tag = sender.tag
        let color = colors[tag % colors.count]
        let detailController = DetailViewController(tag: tag, color: color)
        navigationController?.pushViewController(detailController, animated: true)
    }

    @objc
    private func pushColdStartController(_ sender: UIButton) {
        navigationController?.pushViewController(ColdStartViewController(text: "冷恢复"), animated: true)
    }

    @objc
    private func pushWarmStartController(_ sender: UIButton) {
        navigationController?.pushViewController(WarmStartViewController(text: "热恢复"), animated: true)
    }

    @objc
    private func pushUniqueController(_ sender: UIButton) {
        Navigator.shared.push(URL(string: "//demo/suspend/uniquevc")!, from: UIApplication.shared.keyWindow!)
    }
}

// MARK: - 模拟互斥窗口

extension MainViewController {

    @objc
    private func addflectArea() {
        let urgencyView: UIView = {
            let view = UILabel()
            view.text = "长按删除"
            view.textAlignment = .center
            view.textColor = UIColor.ud.N00
            view.isUserInteractionEnabled = true
            view.tag = Int.random(in: Int.min...Int.max)
            view.backgroundColor = UIColor.systemPink.withAlphaComponent(0.8)
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanEvent(_:)))
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressEvent(_:)))
            longPress.minimumPressDuration = 1
            view.addGestureRecognizer(panGesture)
            view.addGestureRecognizer(longPress)
            return view
        }()
        view.addSubview(urgencyView)
        urgencyView.frame = CGRect(x: UIScreen.main.bounds.width - 80, y: 200, width: 80, height: 40)
        let realFrame = urgencyView.convert(urgencyView.bounds, to: nil)
        SuspendManager.shared.addProtectedZone(realFrame, forKey: "protected\(urgencyView.tag)")
    }

    @objc
    private func handlePanEvent(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        let currentPoint = gesture.location(in: self.view)
        switch gesture.state {
        case .began:
            view.center = currentPoint
        case .changed:
            view.center = currentPoint
        default:
            let realFrame = view.convert(view.bounds, to: nil)
            SuspendManager.shared.addProtectedZone(realFrame, forKey: "protected\(view.tag)")
        }
    }

    @objc
    private func handleLongPressEvent(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        view.removeFromSuperview()
        SuspendManager.shared.removeProtectedZone(forKey: "protected\(view.tag)")
    }
}

// MARK: - 模拟 CustomView

extension MainViewController {

    @objc
    private func addCustomView() {

        let videoVC = VideoController()
        videoVC.videoView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didTapCustomView(_:)))
        )
        videoVC.onFold = { [weak self] videoView in
            self?.foldVideoView(videoView)
        }
        present(videoVC, animated: true, completion: nil)
    }

    @objc
    private func removeCustomView() {
        SuspendManager.shared.removeCustomView(forKey: "video")
    }

    @objc
    private func didTapCustomView(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }
        expandVideoView(view)
    }

    private func expandVideoView(_ view: UIView) {
        // 获取 videoView 的位置
        guard let startFrame = SuspendManager.shared.customFrame(forKey: "video") else { return }
        // 获取 videoView 截屏
        let mockView = UIImageView(image: view.screenshot)
        // 移除 videoView 的约束，避免布局警告
        view.snp.removeConstraints()
        // 转场动画
        SuspendManager.shared.suspendWindow?.addSubview(mockView)
        mockView.frame = startFrame
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
            mockView.frame = UIScreen.main.bounds
        }, completion: { _ in
            // 转场结束后打开 VC
            guard let customView = SuspendManager.shared.removeCustomView(forKey: "video") else {
                mockView.removeFromSuperview()
                return
            }
            let videoVC = VideoController(videoView: customView)
            videoVC.onFold = { [weak self] videoView in
                self?.foldVideoView(videoView)
            }
            self.present(videoVC, animated: false, completion: {
                // present 结束后移除截屏，避免闪烁
                mockView.removeFromSuperview()
            })
        })
    }

    private func foldVideoView(_ view: UIView) {
        // 获取 videoView 截屏
        let mockView = UIImageView(image: view.screenshot)
        // 转场
        SuspendManager.shared.suspendWindow?.addSubview(mockView)
        mockView.frame = UIScreen.main.bounds
        SuspendManager.shared.addCustomView(view, size: CGSize(width: 70, height: 120), forKey: "video")
        SuspendManager.shared.suspendWindow?.layoutIfNeeded()
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn, animations: {
            mockView.frame = SuspendManager.shared.customFrame(forKey: "video") ?? .zero
        }, completion: { _ in
            mockView.removeFromSuperview()
        })
        dismiss(animated: false, completion: nil)
    }

    @objc
    private func addLiveView() {
        let liveView = UIView()
        liveView.backgroundColor = .systemGreen
        let label = UILabel()
        label.text = "直播窗口"
        liveView.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        SuspendManager.shared.addCustomView(
            liveView,
            size: CGSize(width: 144, height: 80),
            forKey: "live",
            level: .middle + 1
        )
    }

    @objc
    private func removeLiveView() {
        SuspendManager.shared.removeCustomView(forKey: "live")
    }

}

// MARK: - 模拟切换账号

extension MainViewController {

    @objc
    private func changeClient(_ sender: UIButton) {
        // 在账号 1 和 2 之间切换
        currentClientId = currentClientId == "1" ? "2" : "1"
        sender.setTitle("当前账号\(currentClientId)（点击切换）", for: .normal)
        SuspendManager.shared.changeClient(id: currentClientId)
        SuspendManager.shared.loadSuspendConfig(forClientId: currentClientId)
    }
}

// MARK: - 更新水印

extension MainViewController {

    @objc
    private func updateWatermark(_ sender: UIButton) {
        let watermark = UIView()
        watermark.backgroundColor = colors.randomElement()!.withAlphaComponent(0.4)
        SuspendManager.shared.updateWatermark(watermark)
    }

    @objc
    private func removeWatermark(_ sender: UIButton) {
        SuspendManager.shared.removeWatermark()
    }
}

extension MainViewController {

    @objc
    private func addRVCView() {
        SuspendManager.shared.addCustomButton(
            UIImage(named: "icon_rvc_outlined")!,
            forKey: "rvc",
            tapHandler: { [weak self] in
                guard let self = self else { return }
                let alert = UIAlertController(title: nil, message: "假装打开了 RVC 页面", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .cancel, handler: { _ in
                    SuspendManager.shared.setSuspendWindowHidden(false, animated: true)
                }))
                SuspendManager.shared.setSuspendWindowHidden(true, animated: true)
                self.present(alert, animated: true)
        })
    }

    @objc
    private func removeRVCView() {
        SuspendManager.shared.removeCustomView(forKey: "rvc")
    }
}
