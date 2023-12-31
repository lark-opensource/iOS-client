//
//  PreviewMeetingContainerView.swift
//  ByteView
//
//  Created by lutingting on 2023/2/6.
//

import Foundation
import ByteViewUI
import UniverseDesignColor

//
//布局视图
//-------------------------------------------------
//                    navBar
//--------_------_-------------------------_-------
//        |      |          topView        |
//------- |------|-------------------------|-------
//        |      |                     displayView
//        |      |         middleView      |
//        | overallLayout                  |
//------- |------|-------------------------|-------
//  contentView  |          deviceBtn      |
//------- |------|-------------------------_-------
//        |      |          callMeTip
//------- |------_---------------------------------
//        |                 commitBtn
//------- |----------------------------------------
//        |                 rejoinplace
//--------_----------------------------------------
//
class PreviewMeetingContainerView: UIView {
    // disable-lint: magic number
    struct Layout {
        static let leftItemSize: CGFloat = Display.pad ? 24 : 28
        static let leftItemLeftPadding: CGFloat = Display.pad ? 16 : 14
        static var verticalPadding: CGFloat { isLandscapeRegular ? 24 : 16 }
        static var horizontalPadding: CGFloat { isLandscapeRegular ? 24 : 16 }
        static var overallBottomOffset: CGFloat { isLandscapeRegular ? 24 : 0 }
        static let commitBtnHeight: CGFloat = 48
        static let safeAreaBottomPadding: CGFloat = Display.iPhoneXSeries ? 8 : 16
        static let deviceItemHeight: CGFloat = 56
        static let deviceBottomInset: CGFloat = 24
        static let naviHeight: CGFloat = Display.pad ? 48 : 44
        static var isLandscapeRegular: Bool { Display.pad && VCScene.isRegular && VCScene.isLandscape }
        static var toastOffset: CGFloat { isLandscapeRegular ? 24 : 16 }
        static var middleViewTopOffset: CGFloat { isLandscapeRegular ? 40 : 32 }
        static var videoStreamRatio: CGFloat { VCScene.isLandscape ? 9.0 / 16.0 : 1.0 }
        static var videoStreamRegularWidth: CGFloat { VCScene.isLandscape ? 704 : 472 }
        static var bottomViewHeight: CGFloat { isLandscapeRegular ? 48 : 134 }
        static var bottomViewTopOffset: CGFloat { isLandscapeRegular ? 24 : 16 }
        static var bottomDeviceSpaceHeight: CGFloat { Layout.verticalPadding + Layout.deviceItemHeight + Layout.deviceBottomInset }
    }

    // enable-lint: magic number
    var rightItemHeight: CGFloat { 28 }
    var rightItemRightInset: CGFloat { 10 }

    var bottomDeviceMinHeight: CGFloat = Layout.bottomDeviceSpaceHeight {
        didSet {
            Util.runInMainThread {
                self.updateViewLayout()
            }
        }
    }

    private(set) lazy var overallLayoutGuide = UILayoutGuide()
    private lazy var topViewLayoutGuide = UILayoutGuide()

    private lazy var contentView = UIView()
    private lazy var displayView = UIView()

    private lazy var visualEffectView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let effectView = UIVisualEffectView(effect: blurEffect)
        effectView.accessibilityLabel = "visualEffectView"
        effectView.isHidden = true
        return effectView
    }()

    private lazy var navBar: UIView = {
        let view = UIView()
        view.addSubview(leftItem)
        view.addSubview(rightItem)
        leftItem.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(Layout.leftItemLeftPadding)
            make.size.equalTo(Layout.leftItemSize)
        }
        rightItem.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(rightItemRightInset)
            make.left.greaterThanOrEqualTo(leftItem.snp.right).offset(8)
            make.height.equalTo(rightItemHeight)
        }
        return view
    }()

    var leftItem: UIView { UIView() }
    var rightItem: UIView { UIView() }

    var topView: UIView { UIView() }
    var middleView: UIView { UIView() }
    var bottomView: UIView { UIView() }


    override init(frame: CGRect) {
        super.init(frame: .zero)
        topViewLayoutGuide.identifier = "topLayoutGuide"

        addSubviews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addSubviews() {
        backgroundColor = .ud.bgBody.withAlphaComponent(0.85) & .ud.bgBase.withAlphaComponent(0.85)
        addSubview(visualEffectView)
        addSubview(contentView)
        addSubview(navBar)
        contentView.addLayoutGuide(overallLayoutGuide)
        contentView.addSubview(displayView)
        contentView.addSubview(bottomView)

        displayView.addLayoutGuide(topViewLayoutGuide)
        displayView.addSubview(topView)
        displayView.addSubview(middleView)
    }

    private func setupLayout() {
        visualEffectView.isHidden = false
        visualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if Display.pad {
            updateLayout(VCScene.isRegular)
        } else {
            setupPhoneLayout()
        }
    }

    func updateLayout(_ isRegular: Bool) {
        guard Display.pad else { return }
        if isRegular {
            updateRegularLayout()
        } else {
            updateCompactLayout()
        }
    }

    private func setupPhoneLayout() {
        navBar.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(Layout.naviHeight)
        }
        contentView.snp.makeConstraints { make in
            make.top.equalTo(navBar.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.bottom)
        }
        overallLayoutGuide.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-Layout.commitBtnHeight - Layout.safeAreaBottomPadding)
        }
        displayView.snp.makeConstraints { make in
            make.top.equalTo(topViewLayoutGuide)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
            make.center.equalTo(overallLayoutGuide)
            make.bottom.equalTo(middleView.snp.bottom).offset(Layout.verticalPadding + Layout.deviceItemHeight + Layout.deviceBottomInset)
        }
        topViewLayoutGuide.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }
        topView.snp.makeConstraints { make in
            make.edges.equalTo(topViewLayoutGuide)
        }
        middleView.snp.makeConstraints { make in
            make.top.equalTo(topViewLayoutGuide.snp.bottom).offset(Layout.middleViewTopOffset)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        bottomView.snp.makeConstraints { make in
            make.top.equalTo(middleView.snp.bottom).priority(.medium)
            make.top.lessThanOrEqualTo(vc.keyboardLayoutGuide.snp.top).offset(-Layout.deviceItemHeight - Layout.verticalPadding * 3 - Layout.commitBtnHeight)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    private func updateRegularLayout() {
        navBar.snp.remakeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(Layout.naviHeight)
        }
        contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        overallLayoutGuide.snp.remakeConstraints { make in
            make.top.greaterThanOrEqualTo(navBar.snp.bottom)
            make.top.equalTo(displayView)
            make.center.equalToSuperview().priority(.low)
            make.width.lessThanOrEqualToSuperview().inset(Layout.horizontalPadding)
            make.bottom.equalTo(bottomView.snp.bottom).offset(Layout.overallBottomOffset)
            make.bottom.lessThanOrEqualToSuperview().offset(isLandscape ? 0 : -16)
        }
        displayView.snp.remakeConstraints { make in
            make.top.equalTo(topViewLayoutGuide)
            make.left.right.equalTo(overallLayoutGuide)
            make.bottom.equalTo(middleView.snp.bottom)
        }
        topViewLayoutGuide.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
        }
        topView.snp.remakeConstraints { make in
            make.edges.equalTo(topViewLayoutGuide)
        }
        middleView.snp.remakeConstraints { make in
            make.top.equalTo(topViewLayoutGuide.snp.bottom).offset(Layout.middleViewTopOffset)
            make.left.right.equalTo(overallLayoutGuide)
            make.width.equalTo(Layout.videoStreamRegularWidth)
            make.height.equalTo(middleView.snp.width).multipliedBy(Layout.videoStreamRatio).priority(.medium)
        }
        bottomView.snp.remakeConstraints { make in
            make.top.equalTo(middleView.snp.bottom).offset(Layout.bottomViewTopOffset)
            make.height.equalTo(Layout.bottomViewHeight)
            make.left.right.equalTo(overallLayoutGuide)
        }
    }

    private func updateCompactLayout() {
        navBar.snp.remakeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
            make.height.equalTo(Layout.naviHeight)
        }
        contentView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        overallLayoutGuide.snp.remakeConstraints { make in
            make.top.greaterThanOrEqualTo(navBar.snp.bottom)
            make.top.equalTo(displayView)
            make.centerY.equalToSuperview().priority(.low)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
            make.bottom.equalTo(bottomView.snp.bottom)
            make.bottom.lessThanOrEqualToSuperview().offset(-16)
        }
        displayView.snp.remakeConstraints { make in
            make.top.equalTo(topViewLayoutGuide)
            make.left.right.equalTo(overallLayoutGuide)
            make.bottom.equalTo(middleView.snp.bottom)
        }
        topViewLayoutGuide.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
        }
        topView.snp.remakeConstraints { make in
            make.edges.equalTo(topViewLayoutGuide)
        }
        middleView.snp.remakeConstraints { make in
            make.top.equalTo(topViewLayoutGuide.snp.bottom).offset(Layout.middleViewTopOffset)
            make.left.right.equalTo(overallLayoutGuide)
            make.height.equalTo(middleView.snp.width).multipliedBy(Layout.videoStreamRatio).priority(.medium)
        }
        bottomView.snp.remakeConstraints { make in
            make.top.equalTo(middleView.snp.bottom).offset(Layout.bottomViewTopOffset)
            make.height.equalTo(Layout.bottomViewHeight)
            make.left.right.equalTo(overallLayoutGuide)
        }
    }

    private func updateViewLayout() {
        guard Display.phone else { return }
        let contentH = overallLayoutGuide.layoutFrame.height
        let topH = topView.frame.height
        let residualHeight = contentH - topH - Layout.middleViewTopOffset - bottomDeviceMinHeight
        let shouldCompressMiddleView = residualHeight < displayView.frame.width
        let height = shouldCompressMiddleView ? residualHeight : displayView.frame.width

        middleView.snp.remakeConstraints { make in
            make.top.equalTo(topViewLayoutGuide.snp.bottom).offset(Layout.middleViewTopOffset)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(height)
        }
        let displayViewBottomInset = shouldCompressMiddleView ? bottomDeviceMinHeight : Layout.bottomDeviceSpaceHeight
        displayView.snp.remakeConstraints { make in
            make.top.equalTo(topViewLayoutGuide)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
            make.center.equalTo(overallLayoutGuide)
            make.bottom.equalTo(middleView.snp.bottom).offset(displayViewBottomInset)
        }
    }

    func updateToastOffset(in view: UIView) {
        let bottomViewMinY = Display.pad ? bottomView.frame.minY : contentView.convert(bottomView.frame.origin, to: view).y
        let offset: CGFloat = view.frame.height - bottomViewMinY + Layout.toastOffset - VCScene.safeAreaInsets.bottom + (Display.pad ? Layout.verticalPadding : 0.0)

        Toast.Context.defaultStyle = .normalPadding(0, keyboard: Display.pad ? Layout.toastOffset - 20 : 148, numberOfLines: 0)
        Toast.update(customInsets: UIEdgeInsets(top: 0, left: 0, bottom: offset, right: 0))
    }

    func resetToastContext() {
        Toast.Context.defaultStyle = .normal
        Toast.update(customInsets: .zero)
    }
}
