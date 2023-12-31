//
//  LobbyNavigationBar.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/5/18.
//

import UIKit
import UniverseDesignIcon
import ByteViewCommon
import ByteViewTracker
import ByteViewUI

protocol LobbyNavigationBarDelegate: AnyObject {
    func topBarDidClickHangup(_ sender: UIButton)
}

class LobbyNavigationBar: UIView {
    enum Layout {
        static let topPhonePadding: CGFloat = 4.0
        static let bottomPhonePadding: CGFloat = 4.0
    }

    // 包含所有控件的wrapper， top针对safearea布局，其他控件均是其子view
    private let contentView = UIView()

    let barContentGuide = UILayoutGuide()
    // disable-lint: magic number
    var layoutGuideMargin: CGFloat { isPhoneLandscape ? 26 : 0 }
    var itemMargin: CGFloat { VCScene.isPhoneLandscape ? Display.iPhoneXSeries ? 60 : 16 : 12 }
    var itemSize: CGSize { isPhoneLandscape ? CGSize(width: 22, height: 22) : CGSize(width: 44, height: 36) }
    var itemLeftSpacing: CGFloat { isPhoneLandscape ? 26 : 12 }
    // enable-lint: magic number

    // 缩小变为悬浮窗按钮
    private(set) lazy var backButton: UIButton = {
        let btn = makeButton(icon: .leftOutlined)
        btn.addTarget(self, action: #selector(didClickBack(_:)), for: .touchUpInside)
        return btn
    }()

    // 会中挂断、离开会议按钮
    private(set) lazy var hangupButton: UIButton = {
        var btn = UIButton()
        btn.isExclusiveTouch = true
        btn.addTarget(self, action: #selector(didClickHangup(_:)), for: .touchUpInside)
        let icon = UDIcon.getIconByKey(.callEndFilled, iconColor: UIColor.ud.staticWhite, size: CGSize(width: 16, height: 16))
        btn.setImage(icon, for: .normal)
        btn.setImage(icon, for: .highlighted)
        btn.layer.masksToBounds = true
        btn.layer.cornerRadius = 6
        btn.vc.setBackgroundColor(UIColor.ud.functionDangerFillDefault, for: .normal)
        btn.vc.setBackgroundColor(UIColor.ud.functionDangerFillPressed, for: .highlighted)
        btn.isHidden = Display.pad
        return btn
    }()

    private lazy var openSceneButton: UIButton = {
        let button = makeButton(icon: .multipleWindowsRightOutlined)
        button.addTarget(self, action: #selector(didOpenScene(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var closeSceneButton: UIButton = {
        let button = makeButton(icon: .closeOutlined)
        button.addTarget(self, action: #selector(didCloseScene(_:)), for: .touchUpInside)
        return button
    }()

    private let barLeftItemsLayoutGuide = UILayoutGuide()
    private let titleLeadingLayoutGuide = UILayoutGuide()
    private let barRightItemsLayoutGuide = UILayoutGuide()

    let viewModel: LobbyViewModel
    weak var delegate: LobbyNavigationBarDelegate?
    init(viewModel: LobbyViewModel, delegate: LobbyNavigationBarDelegate? = nil) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        self.delegate = delegate
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        setupSubviews()
        setupSceneViews()
        updateLayout()
    }

    private func setupSubviews() {
        // 第一层级
        addSubview(contentView)
        addLayoutGuide(titleLeadingLayoutGuide)
        addLayoutGuide(barContentGuide)
        addLayoutGuide(barLeftItemsLayoutGuide)
        addLayoutGuide(barRightItemsLayoutGuide)
        // 第二层级
        contentView.addSubview(backButton)

        contentView.addSubview(hangupButton)
    }

    private func setupSceneViews() {
        if VCScene.supportsMultipleScenes {
            contentView.addSubview(closeSceneButton)
            contentView.addSubview(openSceneButton)
            closeSceneButton.snp.makeConstraints {
                $0.edges.size.equalTo(backButton)
            }
            openSceneButton.snp.makeConstraints {
                $0.centerY.size.equalTo(backButton)
                $0.left.equalTo(backButton.snp.right)
            }
            updateSceneButtons()
            updateSceneButtonIcon()
            NotificationCenter.default.addObserver(self, selector: #selector(sceneDidChange(_:)), name: VCScene.didChangeVcSceneNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        }
    }

    func updateLayout() {
        // 布局
        contentView.snp.remakeConstraints {
            $0.edges.equalTo(barContentGuide)
        }
        barLeftItemsLayoutGuide.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalToSuperview().inset(itemMargin)
            $0.right.equalTo(titleLeadingLayoutGuide.snp.left).offset(-layoutGuideMargin)
        }
        titleLeadingLayoutGuide.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.left.equalTo(barLeftItemsLayoutGuide.snp.right).offset(layoutGuideMargin)
            if VCScene.isPhoneLandscape {
                $0.right.equalTo(barRightItemsLayoutGuide.snp.left).offset(-layoutGuideMargin)
            } else {
                $0.right.equalToSuperview().inset(itemMargin)
            }
        }
        barRightItemsLayoutGuide.snp.remakeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.right.equalToSuperview().inset(itemMargin)
            $0.left.equalTo(titleLeadingLayoutGuide.snp.right).offset(layoutGuideMargin)
        }
        backButton.snp.remakeConstraints {
            $0.left.equalTo(barLeftItemsLayoutGuide.snp.left)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(itemSize)
            $0.right.lessThanOrEqualTo(barLeftItemsLayoutGuide.snp.right)
        }
        hangupButton.snp.remakeConstraints {
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(28)
            if VCScene.isPhoneLandscape {
                $0.left.greaterThanOrEqualTo(barRightItemsLayoutGuide.snp.left)
                $0.right.equalTo(barRightItemsLayoutGuide.snp.right)
            } else {
                $0.right.equalToSuperview().inset(itemMargin)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func updateSceneButtons() {
        if VCScene.isAuxSceneOpen {
            closeSceneButton.isHidden = false
            backButton.isHidden = true
            openSceneButton.isHidden = true
            titleLeadingLayoutGuide.snp.remakeConstraints {
                $0.top.bottom.equalToSuperview()
                $0.left.equalTo(closeSceneButton.snp.right).offset(3)
                $0.right.equalToSuperview().offset(-3)
            }
        } else {
            closeSceneButton.isHidden = true
            backButton.isHidden = false
            openSceneButton.isHidden = false
            titleLeadingLayoutGuide.snp.remakeConstraints {
                $0.top.bottom.equalToSuperview()
                $0.left.equalTo(openSceneButton.snp.right).offset(3)
                $0.right.equalToSuperview().offset(-3)
            }
        }
    }

    private func updateSceneButtonIcon() {
        guard #available(iOS 13, *) else { return }
        let icon: UDIconType = .sepwindowOutlined
        let color = UIColor.ud.iconN1
        openSceneButton.setImage(UDIcon.getIconByKey(icon, iconColor: color, size: CGSize(width: 24, height: 24)), for: .normal)
        openSceneButton.setImage(UDIcon.getIconByKey(icon, iconColor: color.withAlphaComponent(0.5), size: CGSize(width: 24, height: 24)), for: .highlighted)
    }

    private func makeButton(icon: UDIconType, dimension: CGFloat = 24) -> UIButton {
        makeButton(normalImage: UDIcon.getIconByKey(icon, iconColor: UIColor.ud.iconN1, size: CGSize(width: dimension, height: dimension)),
                   highlightedImage: UDIcon.getIconByKey(icon, iconColor: UIColor.ud.iconN1.withAlphaComponent(0.5), size: CGSize(width: dimension, height: dimension)),
                   dimension: dimension)
    }

    private func makeButton(normalImage: UIImage?, highlightedImage: UIImage?, dimension: CGFloat = 24) -> UIButton {
        let btn = UIButton()
        btn.isExclusiveTouch = true
        btn.setImage(normalImage?.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        btn.setImage(highlightedImage?.ud.withTintColor(UIColor.ud.iconN1.withAlphaComponent(0.5)), for: .highlighted)
        btn.addInteraction(type: .highlight)
        return btn
    }

    @objc private func didClickBack(_ sender: UIButton) {
        viewModel.router.setWindowFloating(true)
    }

    @objc private func didClickHangup(_ sender: UIButton) {
        delegate?.topBarDidClickHangup(sender)
    }

    @objc private func sceneDidChange(_ notification: Notification) {
        updateSceneButtons()
    }

    @objc private func didOpenScene(_ sender: UIButton) {
        VCScene.openAuxScene(id: "meeting_\(viewModel.session.sessionId)", title: viewModel.setting.topic) { (_, _) in
            if VCScene.isAuxSceneOpen {
                MeetingTracks.trackCreateAuxWindow(createWay: "button")
            }
        }
    }

    @objc private func didCloseScene(_ sender: UIButton) {
        MeetingTracks.trackCloseAuxWindow()
        VCScene.closeAuxScene()
    }

    @objc private func handleBecomeActive() {
        updateSceneButtonIcon()
    }
}
