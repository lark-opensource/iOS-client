//
//  ChatKeyboardTopExtendToolKitView.swift
//  LarkChat
//
//  Created by JackZhao on 2022/6/20.
//

import Foundation
import UIKit
import RxSwift
import LarkOpenChat
import ByteWebImage
import LKCommonsLogging
import UniverseDesignIcon
import UniverseDesignColor

struct ToolKitConfig {
    // element: label、icon
    static let elementHeight: CGFloat = 16
    static let elementVerticalPadding: CGFloat = 6
    static let labelLeftMargin: CGFloat = 6
    // item: 小组件: label、icon的容器
    static let itemHorizontalLeftPadding: CGFloat = 8
    static let itemHorizontalRightPadding: CGFloat = 10
    static let itemBottomMargin: CGFloat = 8
    static let itemHorizontalMargin: CGFloat = 10
    // 总高度
    static let height: CGFloat = elementHeight + elementVerticalPadding * 2 + itemBottomMargin
}

// 小组件总的容器
final class ChatKeyboardTopExtendToolKitView: UIScrollView {
    private var items: [KeyBoardToolKitItem]

    init(items: [KeyBoardToolKitItem] = []) {
        self.items = items
        super.init(frame: .zero)
        config()
        layout()
    }

    func updateItemViews(_ items: [KeyBoardToolKitItem]) {
        self.items = items
        DispatchQueue.main.async {
            self.layout()
        }
    }

    @inline(__always)
    private func config() {
        self.backgroundColor = UIColor.ud.bgBodyOverlay
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
    }

    private func layout() {
        self.subviews.forEach { $0.removeFromSuperview() }
        var left = self.snp.left
        items.forEach { item in
            let view = ChatKeyboardTopExtendToolKitItemView(item: item)
            self.addSubview(view)
            view.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.bottom.equalTo(-ToolKitConfig.itemBottomMargin)
                make.left.equalTo(left).offset(ToolKitConfig.itemHorizontalMargin)
                // autoLayout无需设置contentSize, 而这里需要指定右边和父view对齐才可自动计算
                if item.identify == items.last?.identify {
                    make.right.equalTo(-ToolKitConfig.itemHorizontalMargin)
                }
            }
            left = view.snp.right
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// 小组件view
final class ChatKeyboardTopExtendToolKitItemView: UIView {
    static let logger = Logger.log(ChatKeyboardTopExtendToolKitItemView.self, category: "Module.LarkChat")

    // 进行圆角和边框设置
    lazy private var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        view.layer.cornerRadius = 8
        view.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        view.layer.borderWidth = 1
        view.layer.masksToBounds = true
        return view
    }()

    lazy private var loadingView: ByteImageView = {
        let imageView = ByteImageView()
        imageView.image = UDIcon.getIconByKey(.loadingOutlined,
                                              iconColor: UIColor.ud.primaryContentDefault,
                                              size: CGSize(width: 16, height: 16))
        return imageView
    }()

    lazy private var iconView: ByteImageView = {
        let imageView = ByteImageView()
        return imageView
    }()

    lazy private var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()

    private var item: KeyBoardToolKitItem
    private let tapEvent = PublishSubject<Void>()
    private let disposeBag = DisposeBag()
    // 是否已经执行完小组件的action事件
    private var isFinishAction = false
    // 是否展示loading态
    private var isShowLoading = false

    init(item: KeyBoardToolKitItem) {
        self.item = item
        super.init(frame: .zero)
        layoutAndRender()
        setEvent()
    }

    private func layoutAndRender() {
        // 目前静态只有两种UI形式： 1. 图+文字； 2. 文字
        // 图+文字 点击后会在图位置出现loading，覆盖原有图；文字形式UI的loading则出现在文字左侧
        var descriptionLabelLeft = self.snp.left
        self.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        containerView.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.width.height.equalTo(ToolKitConfig.elementHeight)
            make.top.equalTo(ToolKitConfig.elementVerticalPadding)
            make.left.equalTo(ToolKitConfig.itemHorizontalLeftPadding)
            make.bottom.equalTo(-ToolKitConfig.elementVerticalPadding)
        }
        loadingView.isHidden = true
        Self.logger.info("layoutAndRender: icon = \(item.icon)")
        if let icon = item.icon {
            containerView.addSubview(iconView)
            iconView.snp.makeConstraints { make in
                make.edges.equalTo(loadingView)
            }
            containerView.bringSubviewToFront(loadingView)
            switch icon {
            case .identify(let key):
                iconView.bt.setLarkImage(with: .default(key: key),
                                         placeholder: UIImage.ud.fromPureColor(UIColor.ud.bgFloatBase)) { res in
                    if case .failure(let error) = res {
                        Self.logger.error("toolKitItemView iconView setLarkImage key:\(key) error", error: error)
                    }
                }
            case .image(let uIImage):
                iconView.image = uIImage
            }
            descriptionLabelLeft = iconView.snp.right
        }
        containerView.addSubview(descriptionLabel)
        let labelLeftOffset = self.item.icon == nil ? ToolKitConfig.itemHorizontalRightPadding : ToolKitConfig.labelLeftMargin
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(ToolKitConfig.elementVerticalPadding)
            make.bottom.equalTo(-ToolKitConfig.elementVerticalPadding)
            make.height.equalTo(ToolKitConfig.elementHeight)
            make.left.equalTo(descriptionLabelLeft).offset(labelLeftOffset)
            make.right.equalTo(-ToolKitConfig.itemHorizontalRightPadding)
            make.width.lessThanOrEqualTo(164)
        }
        descriptionLabel.text = item.title
    }

    private func addRoateAnimation(_ view: UIView) {
        guard view.layer.animation(forKey: "rotate") == nil else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.rotation.z")
        animation.duration = 0.8
        animation.fillMode = .forwards
        animation.repeatCount = .infinity
        animation.values = [0, Double.pi * 2]
        animation.keyTimes = [NSNumber(value: 0.0), NSNumber(value: 1.0)]
        animation.isRemovedOnCompletion = false

        view.layer.add(animation, forKey: "rotate")
    }

    @inline(__always)
    private func removeRotateAnimation(_ view: UIView) {
        view.layer.removeAllAnimations()
    }

    @inline(__always)
    private func setEvent() {
        Self.logger.info("setEvent: item = { name: \(self.item.title), id: \(self.item.identify) } setEvent")
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sendTapEvent)))
        tapEvent
            .debounce(.milliseconds(200), scheduler: MainScheduler.instance)
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] _ in
                self?.tapped()
            }).disposed(by: self.disposeBag)
    }

    @objc
    private func sendTapEvent() {
        tapEvent.onNext(())
    }

    private func tapped() {
        Self.logger.info("tapped: start, item = { name: \(self.item.title), id: \(self.item.identify) } tapped")
        if item.canShowLoading {
            // 延时200ms执行，如果发现请求已经返回，则不展示loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if self.isFinishAction == false, self.isShowLoading == false {
                    enterLoadingState()
                } else {
                    // 重置标记
                    self.isFinishAction = false
                }
            }
            func enterLoadingState() {
                Self.logger.info("tapped: enter loading state")
                // 隐藏icon，展示loaidng
                loadingView.isHidden = false
                iconView.isHidden = true
                descriptionLabel.textColor = UIColor.ud.textDisabled
                // 如果icon为空则重新布局，让label在loadingview右边排列
                if item.icon == nil {
                    descriptionLabel.snp.remakeConstraints { make in
                        make.top.equalTo(ToolKitConfig.elementVerticalPadding)
                        make.bottom.equalTo(-ToolKitConfig.elementVerticalPadding)
                        make.height.equalTo(ToolKitConfig.elementHeight)
                        make.left.equalTo(loadingView.snp.right).offset(ToolKitConfig.labelLeftMargin)
                        make.right.equalTo(-ToolKitConfig.itemHorizontalRightPadding)
                    }
                }
                addRoateAnimation(loadingView)
                self.isShowLoading = true
            }
        }
        // 正在loading时不响应action事件
        if self.isShowLoading == false {
            Self.logger.info("tapped: start to action")
            // 执行小组件的action事件
            self.item.action(self.item.identify, { [weak self] in
                // 此时已经完成了action事件
                self?.actionCallback()
            }, { [weak self] _ in
                // action事件失败
                self?.actionCallback()
            })
        } else {
            Self.logger.info("tapped: action canceled because loading is being displayed")
        }
    }

    private func actionCallback() {
        if self.item.canShowLoading {
            DispatchQueue.main.async {
                self.isFinishAction = true
                // 为了避免UI闪，延迟200ms回到原始状态
                if self.isShowLoading {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        backToNormalState()
                    }
                }
                func backToNormalState() {
                    Self.logger.info("tapped: back to normal state")
                    // 隐藏loading，展示原始icon
                    self.loadingView.isHidden = true
                    self.iconView.isHidden = false
                    self.descriptionLabel.textColor = UIColor.ud.N900
                    // action完成后，如果icon为空则重置为之前单一label的布局
                    if self.item.icon == nil {
                        self.descriptionLabel.snp.remakeConstraints { make in
                            make.top.equalTo(ToolKitConfig.elementVerticalPadding)
                            make.bottom.equalTo(-ToolKitConfig.elementVerticalPadding)
                            make.height.equalTo(ToolKitConfig.elementHeight)
                            make.left.equalTo(ToolKitConfig.labelLeftMargin)
                            make.right.equalTo(-ToolKitConfig.itemHorizontalRightPadding)
                        }
                    }
                    self.removeRotateAnimation(self.loadingView)
                    self.isShowLoading = false
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

enum KeyBoardToolKitIcon {
    case identify(key: String)
    case image(UIImage)
}

// 小组件通用协议
protocol KeyBoardToolKitItem {
    var identify: Int64 { get set }
    var title: String { get set }
    var canShowLoading: Bool { get set }
    var icon: KeyBoardToolKitIcon? { get set }
    var action: TapEvent { get set }
}

struct KeyBoardToolKitEntity: KeyBoardToolKitItem {
    var identify: Int64
    var title: String
    var canShowLoading: Bool
    var icon: KeyBoardToolKitIcon?
    var action: TapEvent
}

typealias TapEvent = (_ identify: Int64,
                      _ successCallback: @escaping () -> Void,
                      _ failureCallback: @escaping (Error) -> Void) -> Void
