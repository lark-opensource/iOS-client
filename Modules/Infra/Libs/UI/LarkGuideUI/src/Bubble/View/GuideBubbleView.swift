//
//  GuideBubbleView.swift
//  LarkGuide
//
//  Created by zhenning on 2020/5/18.
//

import UIKit
import Foundation
import RxSwift
import LKCommonsLogging

protocol GuideMultiBubblesDataSource: AnyObject {
    func numberOfSteps(actionView: GuideBubbleView) -> Int
    func contentForStep(_ actionView: GuideBubbleView, for step: Int) -> BubbleItemConfig?
    func adjustBubblePositionForStep(for step: Int) -> (direction: BubbleArrowDirection, arrowOffset: CGFloat)
}

public final class GuideBubbleView: BaseBubbleView {
    typealias ArrowLayout = BubbleViewArrow.Layout
    private let disposeBag = DisposeBag()
    static let logger = Logger.log(GuideBubbleView.self)
    /// config
    public var bubbleConfig: BubbleItemConfig
    weak var dataSource: GuideMultiBubblesDataSource?
    weak var singleBubbleDelegate: GuideSingleBubbleDelegate?
    weak var multiBubblesDelegate: GuideMultiBubblesViewDelegate?
    /// 气泡矩形内容大小
    var bubbleContentSize: CGSize = CGSize.zero
    private var numberOfSteps: Int = 0
    private(set) var currentStep: Int = 0
    private var isFlowEnd: Bool {
        return isFlow && (currentStep == numberOfSteps - 1)
    }
    /// 是否是多个气泡的流程
    private var isFlow: Bool {
        return (numberOfSteps > 1)
    }
    /// view
    private var bannerView: BubbleBannerView?
    private var textPartView: BubbleTextInfoView
    private var bottomPartView: BubbleBottomView?

    public init(bubbleConfig: BubbleItemConfig) {
        self.bubbleConfig = bubbleConfig
        self.textPartView = BubbleTextInfoView(textPartConfig: bubbleConfig.textConfig)
        super.init()
        setupUI()
        configView()
    }

    public func updateBannerView() {
        bannerView?.update()
    }

    private func setupUI() {
        var viewTop: CGFloat = Layout.contentInset.top
        let contentViewWidth: CGFloat = self.getContentViewWidth()

        // content
        let ges = UITapGestureRecognizer(target: self, action: #selector(contentTapped))
        contentView.addGestureRecognizer(ges)

        // banner
        if let bannerConfig = self.bubbleConfig.bannerConfig {
            self.bannerView = BubbleBannerView(bannerInfoConfig: bannerConfig)
            self.contentView.addSubview(self.bannerView!)
            self.bannerView?.snp.makeConstraints { (make) in
                make.leading.trailing.equalToSuperview()
                make.top.equalTo(viewTop)
                make.size.equalTo(self.bannerView!.intrinsicContentSize)
            }
            viewTop += self.bannerView!.intrinsicContentSize.height
        }

        // text info
        self.contentView.addSubview(self.textPartView)
        self.textPartView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview()
            make.top.equalTo(viewTop)
            make.size.equalTo(self.textPartView.intrinsicContentSize)
        }
        viewTop += self.textPartView.intrinsicContentSize.height

        // bottom
        if let bottomConfig = bubbleConfig.bottomConfig {
            self.bottomPartView = BubbleBottomView(bottomConfig: bottomConfig)
            self.contentView.addSubview(self.bottomPartView!)
            self.bottomPartView?.snp.makeConstraints { (make) in
                make.leading.equalToSuperview()
                make.top.equalTo(viewTop)
                make.width.equalTo(contentViewWidth)
                make.height.equalTo(BubbleBottomView.Layout.viewHeight)
            }
            self.configBottomPartView(bottomConfig: bottomConfig)
            viewTop += BubbleBottomView.Layout.viewHeight
        }
        let contentViewHeight: CGFloat = viewTop + Layout.contentInset.bottom
        self.bubbleContentSize = CGSize(width: contentViewWidth, height: contentViewHeight)
    }

    private func configView() {
        numberOfSteps = 0
        currentStep = 0
    }

    private func configBottomPartView(bottomConfig: BottomConfig) {
        bottomPartView?.rightBtnClickObservable.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            if self.isFlow {
                if self.isFlowEnd {
                    self.multiBubblesDelegate?.didClickEnd(stepView: self)
                } else if bottomConfig.rightBtnInfo.shouldSkip {
                    self.multiBubblesDelegate?.didClickSkip(stepView: self, for: self.currentStep)
                } else {
                    let currentStep = self.nextAction()
                    self.multiBubblesDelegate?.didClickNext(stepView: self, for: currentStep)
                }
            } else {
                self.singleBubbleDelegate?.didClickRightButton(bubbleView: self)
            }
        }).disposed(by: self.disposeBag)

        bottomPartView?.leftBtnClickObservable.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            if self.isFlow {
                if bottomConfig.leftBtnInfo?.shouldSkip ?? false {
                    self.multiBubblesDelegate?.didClickSkip(stepView: self, for: self.currentStep)
                } else {
                    let currentStep = self.previousAction()
                    self.multiBubblesDelegate?.didClickPrevious(stepView: self, for: currentStep)
                }
            } else {
                self.singleBubbleDelegate?.didClickLeftButton(bubbleView: self)
            }
        }).disposed(by: self.disposeBag)
    }

    @objc
    private func contentTapped() {
        self.singleBubbleDelegate?.didTapBubbleView(bubbleView: self)
    }

    // MARK: - Data

    func updateCurrentContent() {
        /// 步骤文案
        let leftText = "\(currentStep + 1)/\(numberOfSteps)"
        let bubbleItem = dataSource?.contentForStep(self, for: currentStep)
        // banner
        if let bannerView = self.bannerView,
            let bannerConfig = bubbleItem?.bannerConfig {
            bannerView.updateContent(bannerInfoConfig: bannerConfig)
        }
        self.textPartView.updateContent(title: bubbleItem?.textConfig.title, detail: bubbleItem?.textConfig.detail ?? "")
        // bottom
        if isFlow {
            self.bottomPartView?.updateByStep(currentStep: currentStep, numberOfSteps: numberOfSteps)
            self.bottomPartView?.leftText = leftText
        } else {
            self.bottomPartView?.leftText = bubbleConfig.bottomConfig?.leftText
        }
        self.bottomPartView?.rightBtnTitle = bubbleItem?.bottomConfig?.rightBtnInfo.title
        self.bottomPartView?.leftBtnTitle = bubbleItem?.bottomConfig?.leftBtnInfo?.title
        // container
        if let containerConfig = bubbleItem?.containerConfig {
            self.bubbleBackColor = containerConfig.bubbleBackColor
            self.bubbleShadowColor = containerConfig.bubbleShadowColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GuideBubbleView {

    func updateSubviewLayout() {
        var viewTop: CGFloat = Layout.contentInset.top
        var contentViewHeight: CGFloat = 0
        let contentViewWidth: CGFloat = self.getContentViewWidth()

        // banner
        if self.bubbleConfig.bannerConfig != nil,
            let bannerView = self.bannerView {
            bannerView.snp.updateConstraints { (make) in
                make.top.equalTo(viewTop)
                make.size.equalTo(bannerView.intrinsicContentSize)
            }
            viewTop += bannerView.intrinsicContentSize.height
        }

        self.textPartView.snp.updateConstraints { (make) in
            make.top.equalTo(viewTop)
            make.size.equalTo(self.textPartView.intrinsicContentSize)
        }
        viewTop += self.textPartView.intrinsicContentSize.height
        /// bottom
        if self.bubbleConfig.bottomConfig != nil,
            let bottomPartView = self.bottomPartView {
            bottomPartView.snp.updateConstraints { (make) in
                make.top.equalTo(viewTop)
                make.width.equalTo(contentViewWidth)
            }
            viewTop += BubbleBottomView.Layout.viewHeight
        }
        contentViewHeight = viewTop + Layout.contentInset.bottom
        self.bubbleContentSize = CGSize(width: contentViewWidth, height: contentViewHeight)

        self.updateDirectionLayoutBySize(bubbleContentSize: self.bubbleContentSize)
    }

    func updateDirectionLayoutBySize(bubbleContentSize: CGSize) {
        guard let (arrowDirection, offset) = dataSource?.adjustBubblePositionForStep(for: currentStep) else { return }
        arrowView.direction = arrowDirection
        var arrowViewSize: CGSize = ArrowLayout.arrowVerticalSize
        var arrowLeft: CGFloat = 0.0
        var arrowTop: CGFloat = 0.0
        var contentTop: CGFloat = 0.0
        var contentBottom: CGFloat = 0.0
        var contentLeft: CGFloat = 0.0
        var contentRight: CGFloat = 0.0
        switch arrowDirection {
        case .left:
            arrowTop = offset
            contentLeft = ArrowLayout.arrowHorizontalSize.width
            arrowViewSize = ArrowLayout.arrowHorizontalSize
        case .up:
            arrowLeft = offset
            contentTop = ArrowLayout.arrowVerticalSize.height
        case .right:
            arrowTop = offset
            arrowViewSize = ArrowLayout.arrowHorizontalSize
            arrowLeft = bubbleContentSize.width
            contentRight = -ArrowLayout.arrowHorizontalSize.width
        case .down:
            arrowLeft = offset
            arrowTop = bubbleContentSize.height
            contentBottom = -ArrowLayout.arrowVerticalSize.height
        }

        arrowView.snp.remakeConstraints { (make) in
            make.size.equalTo(arrowViewSize)
            make.leading.equalToSuperview().offset(arrowLeft)
            make.top.equalToSuperview().offset(arrowTop)
        }

        contentView.snp.updateConstraints { (make) in
            make.leading.equalTo(contentLeft)
            make.trailing.equalTo(contentRight)
            make.top.equalTo(contentTop)
            make.bottom.equalTo(contentBottom)
        }

        GuideBubbleView.logger.debug("updateDirectionLayout:",
                                     additionalData: [
                                        "arrowTop": "\(arrowTop)",
                                        "arrowLeft": "\(arrowLeft)",
                                        "contentTop": "\(contentTop)",
                                        "arrowViewSize": "\(arrowViewSize)"
        ])
    }

    func getContentViewWidth() -> CGFloat {
        var contentViewWidth: CGFloat = 0
        let bannerWidth = self.bannerView?.intrinsicContentSize.width ?? 0
        // if bottom has left text, show the max width
        if self.bubbleConfig.bottomConfig != nil, (bottomPartView?.leftText != nil) {
            contentViewWidth = BaseBubbleView.Layout.defaultMaxWidth
        } else {
            // max the banner & text width
            contentViewWidth = max(bannerWidth, self.textPartView.intrinsicContentSize.width)
        }
        return contentViewWidth
    }
}

extension GuideBubbleView {

    func refreshBubbleContent() {
        numberOfSteps = dataSource?.numberOfSteps(actionView: self) ?? 0
        if isFlow {
            assert((0..<numberOfSteps).contains(currentStep))
        }
        updateCurrentContent()
        updateSubviewLayout()
    }

    @discardableResult
    private func previousAction() -> Int {
        assert((1..<numberOfSteps).contains(currentStep))
        currentStep -= 1
        refreshBubbleContent()
        return currentStep
    }

    @discardableResult
    private func nextAction() -> Int {
        assert((0..<(numberOfSteps - 1)).contains(currentStep))
        currentStep += 1
        refreshBubbleContent()
        return currentStep
    }
}

extension GuideBubbleView {
    enum Layout {
        static let contentInset: UIEdgeInsets = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
    }
}
