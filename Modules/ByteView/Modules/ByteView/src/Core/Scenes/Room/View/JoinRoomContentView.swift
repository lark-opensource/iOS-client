//
//  JoinRoomContentView.swift
//  ByteView
//
//  Created by kiri on 2023/6/9.
//

import Foundation
import ByteViewCommon
import UniverseDesignIcon

enum JoinRoomViewStyle {
    /// 手机布局
    case phone
    /// iPad会中popover
    case popover
}

protocol JoinRoomContentViewDelegate: AnyObject {
    func roomContentViewDidClickScanAgain(_ view: UIView, sender: UIButton)
    func roomContentViewDidClickJoin(_ view: UIView, sender: UIButton)
    func roomContentViewDidClickDisconnect(_ view: UIView)
    func roomContentViewDidClickClose(_ view: UIView, sender: UIButton)
    func roomContentViewDidChangeVerifyCode(_ view: UIView, verifyCode: String)
}

final class JoinRoomContentView: UIView {
    private lazy var headerView = JoinRoomHeaderView(style: style)
    private let contentView = UIView()

    private lazy var loadingView = JoinRoomLoadingView(style: style)
    private lazy var connectView: JoinRoomConnectView = {
        let view = JoinRoomConnectView(style: style)
        view.roomNameLabel.scanAgainButton.addTarget(self, action: #selector(didClickScan(_:)), for: .touchUpInside)
        view.connectButton.addTarget(self, action: #selector(didClickConnect(_:)), for: .touchUpInside)
        view.scanAgainButton.addTarget(self, action: #selector(didClickScan(_:)), for: .touchUpInside)
        return view
    }()

    private lazy var connectedView: RoomConnectedView = {
        let view = RoomConnectedView(style: style)
        view.addButtonAction { [weak self] in
            self?.didClickDisconnect()
        }
        return view
    }()

    private lazy var notFoundView: JoinRoomNotFoundView = {
        let view = JoinRoomNotFoundView(style: style)
        view.scanAgainButton.addTarget(self, action: #selector(didClickScan(_:)), for: .touchUpInside)
        return view
    }()

    private lazy var verifyCodeView: JoinRoomVerifyCodeView = {
        let view = JoinRoomVerifyCodeView(style: style)
        view.textField.codeHandler = { [weak self] in
            guard let self = self else { return }
            self.delegate?.roomContentViewDidChangeVerifyCode(self, verifyCode: $0)
        }
        return view
    }()

    private static let closeBgImage = UIImage.vc.fromColor(.ud.lineBorderCard, size: CGSize(width: 44, height: 44), cornerRadius: 11, insets: UIEdgeInsets(top: 11, left: 11, bottom: 11, right: 11))
    private(set) lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.closeBoldOutlined, iconColor: .ud.N700, size: CGSize(width: 14, height: 14)), for: .normal)
        button.setBackgroundImage(Self.closeBgImage, for: .normal)
        button.addTarget(self, action: #selector(didClickClose(_:)), for: .touchUpInside)
        return button
    }()

    private var contentChildView: JoinRoomChildView {
        guard let state = self.viewModel?.state else { return self.loadingView }
        switch state {
        case .verifyCode:
            return self.verifyCodeView
        case .idle, .scanning:
            return self.loadingView
        case .roomNotFound:
            return self.notFoundView
        case .connected:
            return self.connectedView
        default:
            return self.connectView
        }
    }

    var style: JoinRoomViewStyle {
        didSet {
            if style != oldValue {
                updateStyle()
                self.headerView.style = style
                self.contentChildView.style = style
            }
        }
    }

    weak var delegate: JoinRoomContentViewDelegate?

    init(style: JoinRoomViewStyle) {
        self.style = style
        super.init(frame: CGRect(x: 0, y: 0, width: 375, height: 600))
        addSubview(headerView)
        addSubview(contentView)
        addSubview(closeButton)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalToSuperview().inset(0)
        }
        closeButton.snp.makeConstraints { make in
            make.width.height.equalTo(44)
            make.top.equalToSuperview().inset(2)
            make.right.equalToSuperview().inset(10)
        }
        updateStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateStyle() {
        closeButton.isHidden = style == .popover
        updateBottomMagin()
    }

    private var isScanning: Bool {
        self.viewModel == nil || self.viewModel?.state == .idle || self.viewModel?.state == .scanning
    }

    @objc private func didClickClose(_ sender: UIButton) {
        self.delegate?.roomContentViewDidClickClose(self, sender: sender)
    }

    @objc private func didClickConnect(_ sender: UIButton) {
        self.delegate?.roomContentViewDidClickJoin(self, sender: sender)
    }

    private func didClickDisconnect() {
        self.delegate?.roomContentViewDidClickDisconnect(self)
    }

    @objc private func didClickScan(_ sender: UIButton) {
        self.delegate?.roomContentViewDidClickScanAgain(self, sender: sender)
    }

    var hasBottomSafeArea = false {
        didSet {
            updateBottomMagin()
        }
    }

    private var bottomMargin: CGFloat = 0
    private func updateBottomMagin() {
        let bottomMargin: CGFloat
        if self.isScanning {
            bottomMargin = 0
        } else if viewModel?.state == .connected {
            bottomMargin = 4
        } else if style == .popover || !hasBottomSafeArea {
            bottomMargin = 20
        } else {
            bottomMargin = 12
        }
        if self.bottomMargin != bottomMargin {
            self.bottomMargin = bottomMargin
            contentView.snp.updateConstraints { make in
                make.bottom.equalToSuperview().inset(bottomMargin)
            }
        }
    }

    @RwAtomic private var viewModel: JoinRoomTogetherViewModel?
    func fitContentHeight(maxWidth: CGFloat) -> CGFloat {
        var h = self.headerView.fitContentHeight(maxWidth: maxWidth)
        h += self.contentChildView.fitContentHeight(maxWidth: maxWidth)
        h += self.bottomMargin
        return h
    }

    func updateRoomInfo(_ viewModel: JoinRoomTogetherViewModel) {
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            self.viewModel = viewModel
            Logger.ui.info("updateRoomInfo, state = \(viewModel.state), verifyCodeState = \(viewModel.verifyCodeState), roomNameLen = \(viewModel.roomName?.count ?? 0), width = \(self.frame.width)")
            let child = self.contentChildView
            if child.superview == nil {
                self.contentView.subviews.forEach {
                    $0.removeFromSuperview()
                }
                self.contentView.addSubview(child)
                child.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                if self.style == .popover {
                    self.contentView.layoutIfNeeded()
                }
            }
            self.closeButton.snp.updateConstraints { make in
                make.top.equalToSuperview().offset(self.isScanning ? 2 : 6)
            }
            self.headerView.updateRoomInfo(viewModel)
            child.updateRoomInfo(viewModel)
            self.updateBottomMagin()
        }
    }
}

class JoinRoomChildView: UIView {
    var style: JoinRoomViewStyle {
        didSet {
            if style != oldValue {
                updateStyle()
            }
        }
    }

    init(style: JoinRoomViewStyle) {
        self.style = style
        super.init(frame: CGRect(x: 0, y: 0, width: 375, height: 300))
        self.translatesAutoresizingMaskIntoConstraints = false
        setupViews()
        updateStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {}
    func updateStyle() {}
    func updateRoomInfo(_ viewModel: JoinRoomTogetherViewModel) {}
    func fitContentHeight(maxWidth: CGFloat) -> CGFloat { 0 }
}
