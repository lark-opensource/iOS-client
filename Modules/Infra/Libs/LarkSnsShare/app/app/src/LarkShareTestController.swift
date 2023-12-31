//
//  sharePanelDemo.swift
//  LarkContact
//
//  Created by Siegfried on 2021/12/22.
//

import Foundation
import UIKit
import LarkSnsShare
import RxSwift
import RxCocoa
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignToast

// swiftlint:disable all
class SharePanelDemoViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private lazy var shareTitle = "完全无效的分享面板大图测试文件"
    private lazy var shareURL = "https://bytedance.feishu.cn/docx/doxcnzVPpsJqet3E2SxdcBfMkbe"
    private lazy var webUrlPrepare = WebUrlPrepare(title: shareTitle, webpageURL: shareURL)
    private lazy var contentContext = ShareContentContext.webUrl(webUrlPrepare)
    private lazy var tipPanelMaterial = DowngradeTipPanelMaterial.text(panelTitle: shareTitle, content: shareURL)
    private lazy var shareNum: Int = 5 {
        didSet {
            /// 本地配置
            self.localSharePanel = {
                let pop = PopoverMaterial(sourceView: localShareActionButton,
                                          sourceRect: localShareActionButton.bounds,
                                          direction: .up)
                let sharePanel = LarkSharePanel(
                    with: Array(defaultSharetypes[0..<self.shareNum]),
                    shareContent: contentContext,
                    on: self,
                    popoverMaterial: pop,
                    productLevel: "string",
                    scene: "sdsd"
                )
                sharePanel.downgradeTipPanel = tipPanelMaterial
                sharePanel.getImageURLCallback = {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { }
                    return Bundle.main.url(forResource: "images/ccm_test2", withExtension: "jpg")!
                }
                return sharePanel
            }()
        }
    }
    private lazy var defaultSharetypes: [LarkShareItemType] =
    [.shareImage, .wechat, .timeline, .qq, .weibo, .more(.default), .shareImage, .wechat, .timeline, .qq, .weibo, .more(.default),.shareImage, .wechat]
    private lazy var testVC: UIViewController  = {
        let vc = UIViewController()
        vc.view.backgroundColor = UIColor.ud.B300
        return vc
    }()
    private lazy var customView: UIView = UIView()
    private lazy var circle1: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.red
        view.layer.borderWidth = 2
        view.layer.ud.setBorderColor(UIColor.ud.bgBody)
        return view
    }()
    private lazy var circle2: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.gray
        view.layer.borderWidth = 2
        view.layer.ud.setBorderColor(UIColor.ud.bgBody)
        return view
    }()
    private lazy var circle3: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.blue
        view.layer.borderWidth = 2
        view.layer.ud.setBorderColor(UIColor.ud.bgBody)
        return view
    }()
    private lazy var dataSource: [[ShareSettingItem]] =
    [
        [
            ShareSettingItem(identifier: "id1",
                             icon: UDIcon.linkCopyOutlined,
                             title: "测试标题",
                             subTitle: nil,
                             customView: self.customView,
                             handler: { panel in
                                 panel.present(self.testVC, animated: true)
                             }),
            ShareSettingItem(identifier: "id2",
                             icon: UDIcon.linkCopyOutlined,
                             title: "是的，我只有标题",
                             subTitle: nil,
                             customView: nil,
                             handler: nil)
        ],
        [
            ShareSettingItem(identifier: "id3",
                             icon: UDIcon.linkCopyOutlined,
                             title: "henshin",
                             subTitle: "5s 后我会刷新",
                             customView: nil,
                             handler: nil),
            ShareSettingItem(identifier: "id4",
                             icon: UDIcon.linkCopyOutlined,
                             title: "没人比我更有爱心了",
                             subTitle: "有副标题，没自定义视图的选项",
                             customView: nil,
                             handler: { panel in
                                 panel.present(self.testVC, animated: true)
                             })
        ]
    ]
    
    private lazy var textInputField: UITextField = {
        let input = UITextField()
        input.borderStyle = .roundedRect
        input.layer.cornerRadius = 6.0
        input.layer.masksToBounds = true
        input.placeholder = "默认5(1-13)"
        input.textAlignment = .center
        input.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return input
    }()
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.setTitle("确认", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        button.setTitleColor(UIColor.ud.N00 & UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.backgroundColor = UIColor.ud.primaryContentLoading
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 6.0
        button.addTarget(self, action: #selector(onBtnClicked), for: .touchUpInside)
        return button
    }()
    
    private lazy var localShareActionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor.ud.colorfulGreen
        button.setTitleColor(UIColor.ud.N00, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        button.layer.cornerRadius = 6.0
        button.layer.masksToBounds = true
        button.setTitle("本地小图未降级配置", for: .normal)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(pan))
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        button.addGestureRecognizer(pan)
        button.rx.controlEvent(.touchUpInside).asDriver().drive(onNext: { [weak self] (_) in
            guard let self = self else { return }
            self.presentLocalShareActionSheet()
        }).disposed(by: self.disposeBag)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    private func setup() {
        setupSubViews()
        setupConstraints()
        setupAppearance()
    }
    private func setupSubViews() {
        self.view.addSubview(textInputField)
        self.view.addSubview(button)
        self.view.addSubview(localShareActionButton)
        
        customView.addSubview(circle1)
        customView.addSubview(circle2)
        customView.addSubview(circle3)
    }
    private func setupConstraints() {
        textInputField.snp.makeConstraints { make in
            make.width.equalTo(125)
            make.height.equalTo(44)
            make.left.equalTo(localShareActionButton.snp.left)
            make.bottom.equalTo(localShareActionButton.snp.top).offset(-50)
        }
        
        button.snp.makeConstraints { make in
            make.width.equalTo(50)
            make.height.equalTo(44)
            make.right.equalTo(localShareActionButton.snp.right)
            make.bottom.equalTo(localShareActionButton.snp.top).offset(-50)
        }
        
        localShareActionButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(200)
            make.width.equalTo(200)
            make.height.equalTo(44)
        }
        
        circle1.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
        }
        circle2.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(circle1.snp.leading).offset(5)
        }
        circle3.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(circle2.snp.leading).offset(5)
        }
    }
    private func setupAppearance() {
        self.view.backgroundColor = UIColor.ud.bgBase
    }
    
    /// 确认按钮点击事件
    @objc private func onBtnClicked() {
        if let num = textInputField.text {
            self.shareNum = Int(num) ?? 5
        }
    }

    /// 本地配置
    private lazy var localSharePanel: LarkSharePanel = {
        let pop = PopoverMaterial(sourceView: localShareActionButton,
                                  sourceRect: localShareActionButton.bounds,
                                  direction: .up)
        let sharePanel = LarkSharePanel(
            with: Array(defaultSharetypes[0..<self.shareNum]),
            shareContent: contentContext,
            on: self,
            popoverMaterial: pop,
            productLevel: "test",
            scene: "scene")
        sharePanel.downgradeTipPanel = tipPanelMaterial
        sharePanel.setShareSettingDataSource(dataSource: dataSource)
        sharePanel.getImageURLCallback = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { }
            return Bundle.main.url(forResource: "images/ccm_test2", withExtension: "jpg")!
        }
        return sharePanel
    }()
}

// swiftlint:disable all
extension SharePanelDemoViewController {
    func presentLocalShareActionSheet() {
        self.localSharePanel.show { [weak self] res, type in
            guard let self = self else { return }
            self.handleCallback(result: res, type: type)
        }
    }
    
    func handleCallback(result: ShareResult, type: LarkShareItemType) {
        switch result {
        case .success:
            switch type {
            case .copy:
                UDToast().showTips(with: "已复制到剪贴板", on: self.view)
            case .save:
                UDToast().showSuccess(with: "已保存至相册", on: self.view)
            default:
                print("success")
            }
        case .failure(_, let debugMsg):
            UDToast().showFailure(with: debugMsg, on: self.view)
        }
    }
    
    @objc
    func pan(recognizer:UIPanGestureRecognizer) {
        let point = recognizer.location(in: self.view)
        localShareActionButton.snp.remakeConstraints { make in
            make.centerX.equalTo(point.x)
            make.centerY.equalTo(point.y)
            make.width.equalTo(200)
            make.height.equalTo(44)
            
        }    }
}
