//
//  ChatThemePreviewViewController.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2022/12/22.
//

import UIKit
import Foundation
import RxSwift
import FigmaKit
import LarkUIKit
import EENavigator
import ByteWebImage
import LarkMessageBase
import LKCommonsTracker
import UniverseDesignIcon
import UniverseDesignToast
import UniverseDesignColor
import LarkMessengerInterface

// 聊天主题预览页
final class ChatThemePreviewViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private let disposeBag = DisposeBag()
    private let style: ChatBgImageStyle
    private let tableView = UITableView(frame: .zero)
    private var viewModel: ChatThemePreviewViewModel
    private var displayImageView: ByteImageView = {
        let imageView = ByteImageView()
        imageView.layer.cornerRadius = 10
        imageView.layer.borderWidth = 0.5
        imageView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    private let shadowView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.8)
        return view
    }()
    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgFloat)
    }
    // 确认按钮
    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        let text: String
        switch viewModel.scope {
        case .personalChatTheme:
            text = BundleI18n.LarkChatSetting.Lark_IM_PersonalSetAsWallpaper_Button
        case .groupChatTheme:
            text = BundleI18n.LarkChatSetting.Lark_IM_WallpaperPreviewSetAsGroupWallpaper_Button
        case .unknownChatThemeType:
            assertionFailure("unknown chatThemeType")
            text = BundleI18n.LarkChatSetting.Lark_IM_PersonalSetAsWallpaper_Button
        @unknown default:
            text = BundleI18n.LarkChatSetting.Lark_IM_PersonalSetAsWallpaper_Button
        }
        button.setTitle(text, for: .normal)
        return button
    }()
    private var config: ChatThemePreviewConfig {
        viewModel.config
    }
    private var rightItem: LKBarButtonItem?
    private var scene: ChatThemeScene {
        viewModel.scene
    }

    init(style: ChatBgImageStyle,
         viewModel: ChatThemePreviewViewModel) {
        self.style = style
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        configViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configInit()
    }

    private func configInit() {
        view.backgroundColor = UIColor.ud.bgFloat
        configNavi()
        configBgImageView()
        configConfirmButton()
        configTableView()
        reloadUI()
    }

    private func configNavi() {
        self.title = viewModel.title
        if hasBackPage, navigationItem.leftBarButtonItem == nil {
            addBackItem()
            self.backCallback = { [weak self] in
                self?.viewModel.cancel()
            }
        } else {
            addCancelItem()
            self.closeCallback = { [weak self] in
                self?.viewModel.cancel()
            }
        }

        setNavigationBarRightItem()
    }

    private func setNavigationBarRightItem() {
        let rightItem = LKBarButtonItem(image: getRightIcon())
        rightItem.addTarget(self, action: #selector(navigationBarRightItemTapped), for: .touchUpInside)
        rightItem.isEnabled = true
        self.rightItem = rightItem
        self.navigationItem.rightBarButtonItem = rightItem
    }

    @objc
    private func navigationBarRightItemTapped() {
        viewModel.toogleIsSelectDarkMode()
        reloadUI()
    }

    private func configBgImageView() {
        self.view.addSubview(displayImageView)
        switch style {
        case .image(let img):
            self.displayImageView.backgroundColor = .clear
            self.displayImageView.bt.setLarkImage(with: .default(key: ""),
                                                  placeholder: img)
        case .color(let color):
            self.displayImageView.backgroundColor = color
            self.displayImageView.bt.setLarkImage(with: .default(key: ""))
        case .key(let key, let fsUnit):
            var pass = ImagePassThrough()
            pass.key = key
            pass.fsUnit = fsUnit
            self.displayImageView.backgroundColor = .clear
            self.displayImageView.bt.setLarkImage(with: .default(key: key),
                                                  passThrough: pass)
        case .defalut:
            self.displayImageView.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
            self.displayImageView.bt.setLarkImage(with: .default(key: ""))
        case .unknown:
            break
        }
        displayImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 22, bottom: 110, right: 22))
        }
        displayImageView.addSubview(shadowView)
        shadowView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func getRightIcon() -> UIImage {
        if viewModel.config.isDarkMode {
            return UDIcon.dayOutlined
        } else {
            return UDIcon.nightOutlined
        }
    }

    private func configConfirmButton() {
        self.view.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(displayImageView.snp.bottom).offset(20)
            make.left.equalTo(20)
            make.right.equalTo(-20)
            make.height.equalTo(48)
        }
        confirmButton.titleLabel?.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
        }
        confirmButton.addTarget(self, action: #selector(confrimButtonTapped), for: .touchUpInside)
    }

    @objc
    private func confrimButtonTapped() {
        let style = self.style
        let toast = UDToast.showDefaultLoading(on: self.view)
        self.viewModel.confrim(style: style)
    }

    private func reloadUI() {
        var bgColor: UIColor?
        switch style {
        case .image, .key:
            bgColor = .clear
            shadowView.isHidden = !config.isSelectDarkMode
        case .color(let color):
            bgColor = color
            shadowView.isHidden = !config.isSelectDarkMode
        case .defalut:
            shadowView.isHidden = true
            bgColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        case .unknown:
            break
        }
        if let bgColor = bgColor {
            let color = ChatThemePreviewColorManger.getColor(color: bgColor, config: config)
            displayImageView.backgroundColor = color
        }
        self.rightItem?.button.setImage(getRightIcon(), for: .normal)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.viewModel.traitCollectionDidChange(previousTraitCollection)
        self.reloadUI()
    }

    private func configTableView() {
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        displayImageView.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.lu.register(cellSelf: ChatThemePreviewMessageCell.self)
        tableView.lu.register(cellSelf: ChatThemePreviewTipCell.self)
        tableView.lu.register(cellSelf: ChatThemePreviewMessageReverseCell.self)
    }

    private func configViewModel() {
        viewModel.reloadData
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.tableView.reloadData()
            }).disposed(by: disposeBag)
        viewModel.targetVC = self
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < viewModel.items.count else { return 0 }
        return viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < viewModel.items.count else { return UITableViewCell() }
        let item = viewModel.items[indexPath.row]
        if var cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? ChatThemePreviewBaseCell {
            cell.item = item
            if let cell = cell as? UITableViewCell {
                return cell
            }
            return UITableViewCell()
        }
        return UITableViewCell()
    }
}
