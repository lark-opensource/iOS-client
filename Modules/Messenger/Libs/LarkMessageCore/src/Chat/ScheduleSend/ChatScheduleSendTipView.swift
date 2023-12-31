//
//  ChatScheduleSendTipView.swift
//  LarkChat
//
//  Created by JackZhao on 2022/9/1.
//

import Foundation
import UIKit
import RustPB
import RxRelay
import RxSwift
import RxCocoa
import RichLabel
import LarkModel
import EENavigator
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTheme
import UniverseDesignDialog
import LarkAccountInterface
import LarkMessengerInterface

// 键盘上方定时消息提示
final public class ChatScheduleSendTipView: UIView, LKLabelDelegate {
    // MARK: 对外属性接口
    public var isEnable: Bool = false {
        didSet {
            self.updateStatus(isEnable ? .normal : .disable)
        }
    }
    public var needDisplay: Bool {
        status != nil && status != .hidden
    }
    public var scheduleMsgSendTime: Int64? {
        viewModel.scheduleMsgSendTime
    }
    public var sendSucceedIds: [String] {
        viewModel.sendSucceedIds
    }
    public var deleteIds: [String] {
        viewModel.deleteIds
    }
    public var preferMaxWidth: CGFloat = UIScreen.main.bounds.width {
        didSet {
            tipLabel.preferredMaxLayoutWidth = preferMaxWidth - Config.iconLeftMarigin - Config.iconSize - Config.labelLeftMarigin - Config.labelRightMarigin
        }
    }
    public weak var delegate: ChatScheduleSendTipViewDelegate? {
        didSet {
            self.viewModel.delegate = delegate
        }
    }

    struct Config {
        static let iconSize: CGFloat = 16
        static let iconLeftMarigin: CGFloat = 10
        static let labelRightMarigin: CGFloat = 10
        static let labelLeftMarigin: CGFloat = 8
        static let labelVeriticalMargin: CGFloat = 9
        static let labelFontSize: CGFloat = 14
    }

    // MARK: 私有属性
    private lazy var icon: UIImageView = {
        var imageView = UIImageView()
        return imageView
    }()

    private lazy var tipLabel: LKLabel = {
        let label = LKLabel()
        label.backgroundColor = bgColor
        label.numberOfLines = 0
        label.textAlignment = .left
        label.preferredMaxLayoutWidth = preferMaxWidth - Config.iconLeftMarigin - Config.iconSize - Config.labelLeftMarigin
        return label
    }()

    private lazy var loadingView: ChatLoadingItemView = {
        return ChatLoadingItemView()
    }()

    private var textLinkRange: [String: TapableTextModel] = [:]
    private var isShowLoading: Bool = false {
        didSet {
            if isShowLoading {
                self.loadingView.isHidden = false
                self.loadingView.startLoading()
                return
            }
            self.loadingView.isHidden = true
            self.loadingView.stopLoading()
        }
    }

    private var status: ChatScheduleSendTipViewStatus?
    private let viewModel: ChatScheduleSendTipViewModel
    private let bag = DisposeBag()
    private let bgColor: UIColor

    // MARK: 对外方法
    public init(backgroundColor: UIColor = UIColor.ud.bgBody & UIColor.ud.bgBase,
                viewModel: ChatScheduleSendTipViewModel) {
        self.bgColor = backgroundColor
        self.viewModel = viewModel
        super.init(frame: .zero)
        config()
        initView()
    }

    deinit {
        self.loadingView.stop()
    }

    public func fetchAndObserveData() {
        self.viewModel.fetchAndObserveData()
        self.viewModel.statusObservable
            .skip(1)
            .drive(onNext: { [weak self] status in
                self?.handlerStatusChange(status)
            }).disposed(by: bag)
    }

    // 更新可点击文案 isShow: 是否展示
    public func updateLinkText(isShow: Bool) {
        viewModel.updateLinkText(isShow: isShow)
    }

    // 更新当前ui状态
    public func updateStatus(_ status: ChatScheduleSendTipViewStatus) {
        self.viewModel.updateStatus(status)
    }

    public func attributedLabel(_ label: RichLabel.LKLabel,
                                didSelectText text: String,
                                didSelectRange range: NSRange) -> Bool {
        for (_, model) in self.textLinkRange where model.range == range {
            model.handler()
        }
        return false
    }

    // MARK: 私有方法
    private func config() {
        self.backgroundColor = bgColor
    }

    private func initView() {
        self.addSubview(icon)
        icon.snp.makeConstraints { (make) in
            make.left.equalTo(Config.iconLeftMarigin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Config.iconSize)
        }

        self.addSubview(tipLabel)
        tipLabel.delegate = self
        tipLabel.snp.makeConstraints { (make) in
            make.top.equalTo(Config.labelVeriticalMargin)
            make.left.equalTo(icon.snp.right).offset(Config.labelLeftMarigin)
            make.right.lessThanOrEqualTo(-Config.labelRightMarigin)
            make.bottom.equalTo(-Config.labelVeriticalMargin)
        }

        self.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.centerY.equalTo(tipLabel)
            make.height.equalTo(Config.iconSize)
            make.left.equalTo(tipLabel.snp.right)
        }
    }

    private func handlerStatusChange(_ status: ChatScheduleSendTipViewStatus) {
        self.status = status
        let model: ChatScheduleSendTipModel?
        switch status {
        case .normal:
            model = viewModel.normalModel
        case .disable:
            model = viewModel.disableModel
        case .updating:
            model = viewModel.updatingModel
        case .creating:
            model = viewModel.creatingModel
        case .hidden:
            return
        }
        guard let model = model else {
            assertionFailure("current status: \(status) is not have model")
            return
        }
        updateUIWithModel(model)
    }

    private func updateUIWithModel(_ model: ChatScheduleSendTipModel) {
        tipLabel.attributedText = model.isShowLinkText ? model.text : model.toast
        icon.image = UDIcon.sentScheduledOutlined.ud.withTintColor(model.iconColor)
        tipLabel.tapableRangeList = model.isShowLinkText ? model.textLinkRange.map { $0.value.range } : []
        if let color = model.loadingTextColor {
            self.loadingView.textColor = color
        }
        self.isShowLoading = model.isShowLoading
        self.textLinkRange = model.textLinkRange
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public protocol ChatScheduleSendTipViewDelegate: AnyObject {
    func setScheduleSendTipView(display: Bool)
    // 输入框是否可用
    func getKeyboardEnable() -> Bool
    // 输入框是否显示
    func getKeyboardIsDisplay() -> Bool
    // 是否处理定时消息提示
    func canHandleScheduleTip(messageItems: [RustPB.Basic_V1_ScheduleMessageItem],
                              entity: RustPB.Basic_V1_Entity) -> Bool
    // 提示被点击
    func scheduleTipTapped(model: ChatScheduleSendTipTapModel)
}

// MARK: 业务便利方法
extension ChatScheduleSendTipView {
    @discardableResult
    public func configUpdatingStatusModel() -> Bool {
        viewModel.configUpdatingStatusModel()
    }

    @discardableResult
    public func configCreatingStatusModel() -> Bool {
        viewModel.configCreatingStatusModel()
    }
}
