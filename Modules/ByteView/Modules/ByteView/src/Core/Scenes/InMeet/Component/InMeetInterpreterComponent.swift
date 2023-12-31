//
//  InMeetInterpreterComponent.swift
//  ByteView
//
//  Created by kiri on 2021/4/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import UniverseDesignColor
import ByteViewNetwork

/// 同声传译
final class InMeetInterpreterComponent: InMeetViewComponent, InMeetInterpreterViewModelObserver, InMeetViewChangeListener {
    let httpClient: HttpClient
    private var currentLayoutType: LayoutType

    init(container: InMeetViewContainer, viewModel: InMeetViewModel, layoutContext: VCLayoutContext) throws {
        self.httpClient = viewModel.meeting.httpClient
        self.container = container
        self.currentLayoutType = layoutContext.layoutType
        self.interpretation = viewModel.resolver.resolve(InMeetInterpreterViewModel.self)!
        container.addContent(interpreterSegControl, level: .interpreter)
        container.context.accessoryViews.append(self.interpreterSegControl)
        container.context.addListener(self, for: [.whiteboardMenu, .whiteboardEditAuthority])
        self.interpretation.addObserver(self, fireImmediately: true)
        self.interpretation.isPhoneLandscape = layoutContext.layoutType.isPhoneLandscape
    }

    private weak var container: InMeetViewContainer?
    private var orientation: InterpreterChannelSegmentedControl.Orientation {
        currentLayoutType.isPhoneLandscape ? .vertical : .horizontal
    }
    /// Main Thread only
    private var lastLanguages: [LanguageType] = []
    let interpretation: InMeetInterpreterViewModel
    let disposeBag = DisposeBag()
    lazy var interpreterSegControl: InterpreterChannelSegmentedControl = {
        let view = InterpreterChannelSegmentedControl(frame: .zero)
        view.layer.ud.setShadow(type: .s4Down)
        view.clipsToBounds = false
        view.isHidden = true
        view.setOptions([.backgroundColor(UIColor.ud.bgFloat),
                         .cornerRadius(8.0),
                         .borderWidth(1),
                         .borderColor(UIColor.ud.lineBorderCard),
                         .animationSpringDamping(1.0),
                         .indicatorViewBackgroundColor(UIColor.ud.primaryFillSolid02),
                         .indicatorViewCornerRadius(6.0),
                         .segmentPadding(0)])
        view.addTarget(self, action: #selector(segControlDidChangeValue(_:)), for: .valueChanged)
        return view
    }()

    func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.currentLayoutType = newContext.layoutType
        self.interpretation.isPhoneLandscape = newContext.layoutType.isPhoneLandscape
        if newContext.layoutChangeReason.isOrientationChanged || newContext.layoutChangeReason == .refresh {
            guard self.orientation != interpreterSegControl.controlOrientation else { return }
            self.updateSegControlLayout()
        }
    }

    func updateSegControlLayout() {
        guard let container = self.container else { return }
        interpreterSegControl.controlOrientation = self.orientation
        if interpreterSegControl.controlOrientation == .vertical {
            if let rightLayoutContainer = container.component(by: .mobileLandscapeRightContainer) as? InMeetMobileLandscapeRightComponent {
                rightLayoutContainer.addWidget(.interpreter, self.interpreterSegControl)
            }

        } else {
            if let rightLayoutContainer = container.component(by: .mobileLandscapeRightContainer) as? InMeetMobileLandscapeRightComponent {
                rightLayoutContainer.removeWidget(.interpreter)
                container.addContent(interpreterSegControl, level: .interpreter)
            }
            interpreterSegControl.snp.remakeConstraints { (make) in
                let guide = container.interpreterGuide
                make.centerX.equalToSuperview()
                make.bottom.equalTo(guide)
                make.height.equalTo(44)
                make.width.greaterThanOrEqualTo(156)
            }
        }
    }

    var componentIdentifier: InMeetViewComponentIdentifier {
        .interpreter
    }

    func setupConstraints(container: InMeetViewContainer) {
        updateSegControlLayout()
    }

    func containerDidFirstAppear(container: InMeetViewContainer) {
        interpretation.checkInterpreterIfNeeded()
    }

    func selfInterpreterSettingDidChange(_ setting: InterpreterSetting?) {
        DispatchQueue.main.async {
            self.updateSegControl(setting)
        }
    }

    func whiteboardOperateStatus(isOpaque: Bool) {
        DispatchQueue.main.async {
            // disable-lint: magic number
            let alpha: CGFloat = isOpaque ? 1 : 0.3
            UIView.animate(withDuration: 0.25, animations: {
                self.interpreterSegControl.alpha = alpha
            })
            // enable-lint: magic number
        }
    }

    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        updateSegControlLayout()
    }

    private func updateSegControl(_ setting: InterpreterSetting?) {
        if let setting = setting, setting.isUserConfirm {
            let languages = [setting.firstLanguage, setting.secondLanguage]
            let index = setting.interpretingLanguage.languageType == setting.firstLanguage.languageType ? 0 : 1
            if lastLanguages == languages {
                if index != interpreterSegControl.index {
                    // 文案相同index不同, 只改index
                    interpreterSegControl.setIndex(index)
                }
            } else {
                // 文案不同, 改titles和index
                httpClient.i18n.get(languages.map { $0.despI18NKey }) { [weak self] result in
                    guard let self = self else { return }
                    if let i18nValues = result.value {
                        let langs: [[String: LanguageType]] = languages.map { [i18nValues[$0.despI18NKey] ?? "": $0] }
                        let segments = LabelSegment.segments(withTitles: langs)
                        DispatchQueue.main.async {
                            self.interpreterSegControl.segments = segments
                            if index > 0 {
                                self.interpreterSegControl.setIndex(index, animated: false)
                            }
                            self.lastLanguages = languages
                        }
                    }
                }
            }
            interpreterSegControl.isHidden = false
            self.container?.context.isInterpreter = true
        } else {
            interpreterSegControl.isHidden = true
            self.container?.context.isInterpreter = false
        }
    }

    @objc func segControlDidChangeValue(_: Any) {
        if let afterLang = lastLanguages[safeAccess: interpreterSegControl.index],
            let beforeLang = lastLanguages.first(where: { $0 != afterLang }) {
            MeetingTracksV2.trackChooseInterpretationLang(beforeLang: beforeLang.languageType,
                                                          afterLang: afterLang.languageType)
            interpretation.selectInterpretingChannel(afterLang)
        }
    }
}
