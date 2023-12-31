//
//  FollowContainerViewController+Onboarding.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/4/13.
//

import UIKit
import SnapKit
import ByteViewUDColor
import ByteViewCommon
import ByteViewUI

///  Guide or Onboarding
private extension UIView {
    var isVisible: Bool {
        if self.window == nil {
            return false
        }

        var view: UIView? = self
        while view != nil {
            if view!.isHidden {
                return false
            }
            view = view?.superview
        }
        return true
    }
}

extension FollowContainerViewController {

    private struct Guide {
        let content: GuideStyle
        let anchorView: UIView
        let guideDirection: GuideDirection
        let action: () -> Void
        let beforeAction: ((_ guideView: UIView) -> Void)?
        let cleanupAction: (() -> Void)?
        let distance: CGFloat?

        init(content: String,
             anchorView: UIView,
             guideDirection: GuideDirection,
             action: @escaping () -> Void,
             beforeAction: ((_ guideView: UIView) -> Void)? = nil,
             afterAction: (() -> Void)? = nil,
             distance: CGFloat? = nil) {
            self.content = .plain(content: content)
            self.anchorView = anchorView
            self.guideDirection = guideDirection
            self.action = action
            self.beforeAction = beforeAction
            self.cleanupAction = afterAction
            self.distance = distance
        }

        init(focusContent: String,
             anchorView: UIView,
             guideDirection: GuideDirection,
             action: @escaping () -> Void,
             beforeAction: ((_ guideView: UIView) -> Void)? = nil,
             afterAction: (() -> Void)? = nil,
             distance: CGFloat? = nil) {
            self.content = .focusPlain(content: focusContent)
            self.anchorView = anchorView
            self.guideDirection = guideDirection
            self.action = action
            self.beforeAction = beforeAction
            self.cleanupAction = afterAction
            self.distance = distance
        }
    }

    func removeOnboardingGuide() {
        guard let guideView = self.guideView else {
            return
        }

        guideView.cleanupAction?()
        guideView.removeFromSuperview()
        self.guideView = nil
    }

    /// 操作栏高度
    // disable-lint: magic number
    private var operationViewHeight: CGFloat {
        let isSteepStyle: Bool = viewModel.context.meetingLayoutStyle == .fullscreen
        let isPhone: Bool = Display.phone
        let isPhonePortrait: Bool = currentLayoutContext.layoutType.isCompact
        switch (isSteepStyle, isPhone, isPhonePortrait) {
        case (false, true, true): // iPhone非沉浸态竖屏
            return 40.0
        case (true, true, true): // iPhone沉浸态竖屏
            return (Display.phone && !Display.iPhoneXSeries) ? 32.0 : 52.0 // 非刘海屏手机特化显示
        case (false, true, false): // iPhone非沉浸态横屏
            return 53.0
        case (true, true, false): // iPhone沉浸态横屏
            return 43.0
        case (false, false, _): // iPad非沉浸态
            return 40.0
        case (true, false, _): // iPad沉浸态
            return 34.0
        }
    }

    // nolint: long_function
    func showGuideViewIfNeeded() {
        self.removeOnboardingGuide()
        guard !self.isGalleryCellMode,
              self.guideView == nil, let inMeetViewContainer = self.container else {
            return
        }

        var guides = [Guide]()
        let documents = viewModel.localDocuments
        if viewModel.needsToShowNavBackGuide()
            && operationView.backToLastFileButton.isVisible
            && documents.count >= 2 {
            guides.append(Guide(content: I18n.View_VM_TapToGoBackToFile,
                                anchorView: operationView.backToLastFileButton,
                                guideDirection: Display.phone ? .top : .bottom,
                                action: { [weak self] in
                self?.viewModel.didShowNavBackGuide()
            }, distance: 4))
        }

        if let container = self.container,
           viewModel.needsToShowFullScreenMicBarGuide(container: container),
           let padMicBar = container.fullscreenMicBar?.padMicBar {
            let content = I18n.View_G_AccessExpandToolbar_Toast
            let dotView = UIView()
            dotView.backgroundColor = UIColor.ud.primaryFillHover.withAlphaComponent(0.2)
            dotView.layer.cornerRadius = 17.0
            let dotCenter = UIView()
            dotCenter.backgroundColor = UIColor.ud.primaryFillHover
            dotCenter.layer.cornerRadius = 6.0
            dotView.addSubview(dotCenter)
            dotCenter.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 12.0, height: 12.0))
                make.center.equalToSuperview()
            }
            let guide = Guide(content: content,
                              anchorView: dotView,
                              guideDirection: .top,
                              action: { [weak self] in
                self?.viewModel.didShowFullScreenMicBarGuide()
            },
                              beforeAction: { [weak self, weak padMicBar] _ in
                guard let self = self,
                      let padMicBar = padMicBar else {
                    return
                }
                padMicBar.view.addSubview(dotView)
                dotView.snp.makeConstraints { make in
                    make.size.equalTo(CGSize(width: 34.0, height: 34.0))
                    make.centerX.equalTo(padMicBar.expandBtn)
                    make.centerY.equalTo(padMicBar.expandBtn.snp.top).offset(13.0)
                }
                self.hitDetectView.layoutIfNeeded()
            }, afterAction: {
                dotView.removeFromSuperview()
            }, distance: 4)

            guides.append(guide)
        }

        if viewModel.needsToShowFollowerFreeSkimGuide() {
            let dotView = UIView()
            dotView.backgroundColor = UIColor.ud.primaryFillHover.withAlphaComponent(0.2)
            dotView.layer.cornerRadius = 27.0
            let dotCenter = UIView()
            dotCenter.backgroundColor = UIColor.ud.primaryFillHover
            dotCenter.layer.cornerRadius = 10.0
            dotView.addSubview(dotCenter)
            dotCenter.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 20.0, height: 20.0))
                make.center.equalToSuperview()
            }

            guides.append(Guide(content: I18n.View_VM_TapToViewOnYourOwn,
                                anchorView: dotView,
                                guideDirection: .bottom,
                                action: { [weak self] in
                self?.viewModel.didShowFollowerFreeSkimGuide()
            },
                                beforeAction: { [weak self] _ in
                                    guard let self = self else {
                                        return
                                    }
                                    self.hitDetectView.addSubview(dotView)
                                    dotView.snp.makeConstraints { make in
                                        make.size.equalTo(CGSize(width: 54.0, height: 54.0))
                                        make.centerX.equalToSuperview()
                                        make.centerY.equalToSuperview().offset(-27)
                                    }
                                    self.hitDetectView.layoutIfNeeded()
            },
                                afterAction: {
                                    dotView.removeFromSuperview()
            }, distance: 4))
        }

        if viewModel.needsToShowFollowerFollowPresenterGuide()
            && operationView.backToPresenterButton.isVisible {
            guides.append(Guide(content: I18n.View_VM_TapToFollowPersonSharing,
                                anchorView: operationView.backToPresenterButton,
                                guideDirection: Display.phone ? .top : .bottom,
                                action: { [weak self] in
                self?.viewModel.didShowFollowerFollowPresenterGuide()
            }, distance: 4))
        }

        // 点击「共享指示区」可唤起工具栏
        if viewModel.needsToShowFollowExapndToolbarSharingBarGuide() {
            if Display.phone {
                // iPhone布局
                let isPortrait: Bool = currentLayoutContext.layoutType.isCompact
                let dotView = UIView()
                dotView.backgroundColor = UIColor.ud.primaryFillHover.withAlphaComponent(0.2)
                dotView.layer.cornerRadius = isPortrait ? 16.0 : 12.0
                let dotCenter = UIView()
                dotCenter.backgroundColor = UIColor.ud.primaryFillHover
                dotCenter.layer.cornerRadius = isPortrait ? 6.0 : 4.5
                dotView.addSubview(dotCenter)
                dotCenter.snp.makeConstraints { make in
                    let sideLength: CGFloat = isPortrait ? 12.0 : 9.0
                    make.size.equalTo(CGSize(width: sideLength, height: sideLength))
                    make.center.equalToSuperview()
                }
                // add onBoarding view
                let guideRootView = inMeetViewContainer.addContent(dotView, level: .guide)
                // mask under onboarding & operation view
                let topMaskView = UIView(frame: .infinite)
                topMaskView.isUserInteractionEnabled = false
                topMaskView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.8)
                let bottomMaskView = UIView(frame: .infinite)
                bottomMaskView.isUserInteractionEnabled = false
                bottomMaskView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.8)
                let mockOperationView = UIView(frame: CGRect(x: 0,
                                                             y: guideRootView.frame.maxY - self.operationViewHeight,
                                                             width: guideRootView.frame.width,
                                                             height: self.operationViewHeight))
                mockOperationView.backgroundColor = .clear
                inMeetViewContainer.addContent(mockOperationView, level: .guide)
                guides.append(Guide(focusContent: I18n.View_G_AccessExpandToolbar_Toast,
                                    anchorView: mockOperationView,
                                    guideDirection: .top,
                                    action: { [weak self] in
                    self?.viewModel.didShowFollowExapndToolbarSharingBarGuide()
                }, beforeAction: { [weak self] _ in
                    guard let self = self,
                          let inMeetViewContainer = self.container else {
                              return
                          }
                    // add onBoarding mask
                    inMeetViewContainer.addContent(topMaskView, level: .guide)
                    topMaskView.snp.makeConstraints {
                        $0.left.right.top.equalToSuperview()
                        $0.bottom.equalToSuperview().inset(self.operationViewHeight)
                    }
                    inMeetViewContainer.addContent(bottomMaskView, level: .guide)
                    bottomMaskView.snp.makeConstraints {
                        $0.left.right.bottom.equalToSuperview()
                        $0.top.equalTo(topMaskView.snp.bottom).offset(self.operationViewHeight)
                    }
                    dotView.snp.makeConstraints { make in
                        let sideLength: CGFloat = isPortrait ? 32.0 : 24.0
                        make.size.equalTo(CGSize(width: sideLength, height: sideLength))
                        make.centerX.equalToSuperview()
                        make.bottom.equalToSuperview().inset(self.operationViewHeight - 1.0 - sideLength)
                    }
                    self.operationView.layoutIfNeeded()
                    mockOperationView.layoutIfNeeded()
                    inMeetViewContainer.view.layoutIfNeeded()
                }, afterAction: {
                    Util.runInMainThread {
                        [dotView, topMaskView, bottomMaskView, mockOperationView].forEach {
                            $0.removeFromSuperview()
                        }
                    }
                }, distance: 4.0))
            } else {
                // iPad布局
                let dotView = UIView()
                dotView.backgroundColor = UIColor.ud.primaryFillHover.withAlphaComponent(0.2)
                dotView.layer.cornerRadius = 17.0
                let dotCenter = UIView()
                dotCenter.backgroundColor = UIColor.ud.primaryFillHover
                dotCenter.layer.cornerRadius = 6.25
                dotView.addSubview(dotCenter)
                dotCenter.snp.makeConstraints { make in
                    make.size.equalTo(CGSize(width: 12.5, height: 12.5))
                    make.center.equalToSuperview()
                }
                guides.append(Guide(
                    content: I18n.View_G_AccessExpandToolbar_Toast,
                    anchorView: operationView,
                    guideDirection: .bottom,
                    action: { [weak self] in
                        self?.viewModel.didShowFollowExapndToolbarSharingBarGuide()
                    },
                    beforeAction: { [weak self] _ in
                        guard let self = self else {
                            return
                        }
                        self.operationView.addSubview(dotView)
                        dotView.snp.makeConstraints { make in
                            make.size.equalTo(CGSize(width: 34.0, height: 34.0))
                            make.center.equalToSuperview()
                        }
                        self.operationView.layoutIfNeeded()
                    },
                    afterAction: {
                        dotView.removeFromSuperview()
                    },
                    distance: 4.0)
                )
            }
        }

        // 当前你处于“自由浏览”状态，点击共享人头像可跟随共享人浏览
        if viewModel.needsToShowFollowClickAvatarToFollowGuide() {
            guides.append(Guide(content: I18n.View_G_ViewOnYourOwnClickToFollow_Toast,
                                anchorView: directionView,
                                guideDirection: .left,
                                action: { [weak self] in
                self?.viewModel.didShowFollowClickAvatarToFollowGuide()
            }, distance: 5.0))
        }

        guard let guide = guides.first else {
            return
        }

        let guideView = GuideView(frame: .zero)
        self.guideView = guideView

        guide.beforeAction?(guideView)
        if case .focusPlain = guide.content { // 有蒙层，需单独显示在GuideContent的层级上
            inMeetViewContainer.addContent(guideView, level: .guide)
        } else {
            view.addSubview(guideView)
        }
        guideView.cleanupAction = guide.cleanupAction

        guideView.sureAction = { [weak self] _ in
            guide.action()
            self?.removeOnboardingGuide()
            self?.viewModel.manualGuideTrigger.accept(Void())
        }

        guideView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        guideView.setStyle(guide.content, on: guide.guideDirection, of: guide.anchorView, distance: guide.distance)
    }
    // enable-lint: magic number
}
