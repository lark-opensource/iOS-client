//
//  InMeetSubtitleView.swift
//  ByteView
//
//  Created by 武嘉晟 on 2020/4/7.
//
//  会中字幕视图文件

import SnapKit
import ByteViewUI
import ByteViewCommon
import UIKit
import RxSwift
import Lottie
import RichLabel
import UniverseDesignIcon

/// Loding动效
enum SubtitleLoadingStyle {
    case noNeed
    case circle
    case dot
}

// MARK: - 会中字幕视图
class InMeetSubtitleView: UIView {

    /// 字幕状态
    private var subtitleStatus: AsrSubtitleStatus = .unknown

    /// 字幕表视图
    private lazy var subtitleView1 = InMeetSubtitleItemView()

    private lazy var subtitleView2 = InMeetSubtitleItemView()

    /// 关闭按钮
    private lazy var closeButton: UIButton = {
        let button = UIButton()

        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.staticWhite.withAlphaComponent(0.6), size: CGSize(width: 16, height: 16)), for: .normal)
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        return button
    }()

    private lazy var padCloseButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.staticWhite, size: CGSize(width: 16, height: 16)), for: .normal)
        button.addTarget(self, action: #selector(close), for: .touchUpInside)
        button.vc.setBackgroundColor(.clear, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.staticWhite.withAlphaComponent(0.15), for: .highlighted)
        return button
    }()

    lazy var openHistoryButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.subtitlesFullOutlined, iconColor: UIColor.ud.staticWhite, size: CGSize(width: 16, height: 16)), for: .normal)
        button.vc.setBackgroundColor(.clear, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.staticWhite.withAlphaComponent(0.15), for: .highlighted)
        return button
    }()

    private lazy var rightView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        let vLine = UIView()
        vLine.backgroundColor = UIColor.ud.staticWhite.withAlphaComponent(0.2)
        v.addSubview(vLine)
        vLine.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
            make.width.equalTo(0.5)
        }
        let hLine = UIView()
        hLine.backgroundColor = UIColor.ud.staticWhite.withAlphaComponent(0.2)
        v.addSubview(hLine)
        hLine.snp.makeConstraints { make in
            make.left.right.centerY.equalToSuperview()
            make.height.equalTo(0.5)
        }
        v.addSubview(padCloseButton)
        padCloseButton.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.5)
        }
        v.addSubview(openHistoryButton)
        openHistoryButton.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.5)
        }
        return v
    }()

    /// 关闭字幕面板Block
    var closeSubtileBlock: (() -> Void)?

    var tapGest: UITapGestureRecognizer?

    //  展示的状态view
    private lazy var subtitleStateView = SubtitleLoadingTipView()

    private var timer: Timer?

    var viewModel: FloatingSubtitleViewModel

    lazy var subtitleDataHandler: InMeetSubtitleDataHandler = {
        let handler = InMeetSubtitleDataHandler()
        handler.layoutChangedBlock = { [weak self] in
            self?.reloadSubtitleView()
        }
        return handler
    }()

    private var contentRightOffset: CGFloat {
        Display.pad ? -40 : -10
    }


    init(viewModel: FloatingSubtitleViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        clipsToBounds = true
        backgroundColor = UIColor.ud.vcTokenMeetingBgFeed
        layer.cornerRadius = 8.0
        layer.borderWidth = 0.5
        layer.vc.borderColor = UIColor.ud.staticWhite.withAlphaComponent(0.1)
        setupViews()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true, block: { [weak self] _ in
            self?.showSubtitleSmooth()
        })
    }


    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        timer?.invalidate()
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === self.tapGest else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
        let eventsFilter: [Bool] = [!subtitleDataHandler.speakers.isEmpty,
                                   {
                                    switch subtitleStatus {
                                    case .discontinuous, .translation:
                                        return true
                                    case .openSuccessed(let isRecover, _):
                                        return isRecover
                                    default:
                                        return false
                                    }
                                   }()]
        let shouldBegin = eventsFilter.contains(true)
        return shouldBegin
    }

    /// 关闭字幕
    @objc
    private func close() {
        closeSubtileBlock?()
    }

    private func setupViews() {
        addSubview(subtitleView1)
        addSubview(subtitleView2)
        if Display.pad {
            addSubview(rightView)
        } else {
            addSubview(closeButton)
        }
        layoutSubtitle()
    }

    func trimSubtitleViewDatasWhenTransition() {
        removeInvalidSubtitlesIfNeeded()
    }

    func restoreSubtitlesFrom(subtitles: [Subtitle]) {
        subtitleDataHandler.removeAllData()
        for subtitleItem in subtitles {
            subtitleDataHandler.updateSubtitle(SubtitleViewData(subtitle: subtitleItem, phraseStatus: viewModel.subtitle.phraseStatus))
        }
        if let lastSubtitle = subtitles.last {
            subtitleStatus = .translation(lastSubtitle)
        }
        removeStateChangeView()
        reloadSubtitleView()
    }

    /// 更新状态（外部调用）
    /// - Parameter status: 状态
    func updateSubtitleStatus(status: AsrSubtitleStatus) {
        guard subtitleStatus != status else {
            //  避免相同status重复调用
            return
        }
        subtitleStatus = status
        switch status {
        case .translation(let subtitle):
            if subtitle.data.subtitleType != .translation {
                //  过滤掉其他类型的字幕
                return
            }
            //  翻译字幕中
            removeStateChangeView()
            subtitleDataHandler.updateSubtitle(SubtitleViewData(subtitle: subtitle, phraseStatus: viewModel.subtitle.phraseStatus))
        case .discontinuous:
            // TODO: remove discontinuous
            break
        default:
            updateStatusContent(status: status)
        }
    }

    /// 清除字幕并且显示翻译服务切换中
    func clearAllSubtitlesAndSwipeUpForPreviousSubtitles() {
        showStateView(text: I18n.View_G_SwitchTranslateLanguage)
    }
    /// 更新字幕状态UI
    /// - Parameter status: 状态
    private func updateStatusContent(status: AsrSubtitleStatus) {
        switch status {
        case .opening:
            //  正在开启字幕，显示 I18n.View_G_TurningSubtitlesOn
            showStateView(text: I18n.View_G_TurningSubtitlesOn, style: .circle)
        case .openSuccessed(let isRecover, let isAllMuted):
            guard !isRecover else { return }
            if !isAllMuted {
                //  非恢复状态显示聆听中 I18n.View_G_Listening
                showStateView(text: I18n.View_G_Listening, style: .dot)
            } else {
                // 会中无人开启麦克风 显示当前无人发言
                showStateView(text: I18n.View_G_NoOneSpeaking_Text)
            }
        case .recoverableException:
            //  显示重新连接中 View_G_SubtitlesReconnecting
            showStateView(text: I18n.View_G_SubtitlesReconnecting)
        case .openFailed:
            showStateView(text: I18n.View_G_SubtitleUnavailable_EmptyState)
        default:
            break
        }
    }
}
// MARK: - 会中字幕视图UI状态变更
extension InMeetSubtitleView {
    /// 字幕区域中央显示Tips
    /// - Parameters:
    ///   - text: 内容
    ///   - showLoading: 是否需要转圈圈的img
    private func showStateView(text: String, style: SubtitleLoadingStyle = .noNeed) {
        //  防止重复调用
        removeStateChangeView()
        //  不要漏出字幕
        subtitleView1.isHidden = true
        subtitleView2.isHidden = true
        addSubview(subtitleStateView)
        subtitleStateView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        subtitleStateView.start(with: text, withLoadingSyle: style)
    }
    /// 移除盖在字幕上面的状态
    private func removeStateChangeView() {
        //  恢复字幕显示
        guard subtitleView1.isHidden else { return }
        subtitleView1.isHidden = false
        subtitleView2.isHidden = subtitleDataHandler.displayType == .single
        subtitleStateView.end()
        subtitleStateView.removeFromSuperview()
        reloadSubtitleView()
    }

    private func showSubtitleSmooth() {
        if subtitleDataHandler.isShowAll { return }
        reloadData()
    }
}
// MARK: - 会中字幕视图UI工具方法
extension InMeetSubtitleView {

    /// 字幕视图布局
    func layoutSubtitle() {
        layoutSubtitleViews()
        if Display.pad {
            rightView.snp.makeConstraints { make in
                make.top.right.bottom.equalToSuperview()
                make.width.equalTo(32)
            }
        } else {
            closeButton.snp.remakeConstraints { (maker) in
                maker.top.right.equalToSuperview()
                maker.size.equalTo(CGSize(width: 32, height: 32))
            }
        }
    }

    func layoutSubtitleViews() {
        if subtitleDataHandler.displayType == .single {
            subtitleView1.snp.remakeConstraints { make in
                make.top.equalTo(8)
                make.left.equalTo(10)
                make.height.equalTo(83)
                make.right.equalTo(contentRightOffset)
            }
            subtitleView2.snp.remakeConstraints { make in
                make.left.right.equalTo(subtitleView1)
                make.height.equalTo(0)
                make.top.equalTo(49)
            }
        } else {
            subtitleView1.snp.remakeConstraints { make in
                make.top.equalTo(8)
                make.left.equalTo(10)
                make.height.equalTo(39)
                make.right.equalTo(contentRightOffset)
            }
            subtitleView2.snp.remakeConstraints { make in
                make.left.right.height.equalTo(subtitleView1)
                make.top.equalTo(51)
            }
        }
    }

    func reloadSubtitleView() {
        subtitleView2.isHidden = subtitleDataHandler.displayType == .single
        layoutSubtitleViews()
        DispatchQueue.main.async {
            self.reloadData()
        }
    }

    func reloadData() {
        if subtitleDataHandler.speakers.isEmpty { return }
        subtitleView1.config(with: subtitleDataHandler.speakers[0], isAlighRight: viewModel.subtitle.isSubtitleAlignRight)
        if subtitleDataHandler.speakers.count > 1 {
            subtitleView2.config(with: subtitleDataHandler.speakers[1], isAlighRight: viewModel.subtitle.isSubtitleAlignRight)
        }
        subtitleDataHandler.updateWordEnd()
    }

    func removeInvalidSubtitlesIfNeeded() {
        subtitleDataHandler.removeInvalidSubtitlesIfNeeded()
        reloadData()
    }
}

// MARK: - 会中字幕使用的loadingView（内部）
private class SubtitleLoadingTipView: UIView {
    private lazy var loadingView = SubtitleLoadingTipView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        isUserInteractionEnabled = false
    }
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupViews() {
        addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(20)
        }
    }
    func start(with text: String, withLoadingSyle style: SubtitleLoadingStyle) {
        loadingView.start(with: text, withLoadingSyle: style)
    }
    func end() {
        loadingView.stop()
    }
}
extension SubtitleLoadingTipView {
    // MARK: - 会中字幕使用的loadingView（SubtitleLoadingTipStackView内部使用）
    private class SubtitleLoadingTipView: UIView {
        private lazy var circleLoadingView = LoadingView(style: .blue)
        private lazy var tipLabel: UILabel = {
            let label = UILabel()
            label.textColor = UIColor.ud.primaryOnPrimaryFill
            label.font = UIFont.systemFont(ofSize: 14)
            return label
        }()
        private lazy var dotLoadingView = DotAnimtedView()
        override init(frame: CGRect) {
            super.init(frame: frame)
            backgroundColor = .clear
            addSubview(circleLoadingView)
            addSubview(tipLabel)
            addSubview(dotLoadingView)
            autolayoutSubviews()
            isUserInteractionEnabled = false
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        private func autolayoutSubviews() {
            circleLoadingView.snp.makeConstraints { (maker) in
                maker.left.equalToSuperview()
                maker.centerY.equalToSuperview()
                maker.width.height.equalTo(24)
            }
            tipLabel.snp.makeConstraints { (maker) in
                maker.centerY.equalTo(circleLoadingView)
                maker.left.equalTo(circleLoadingView.snp.right).offset(8)
                maker.right.lessThanOrEqualToSuperview()
                maker.width.equalTo(0).priority(.low)
            }
            dotLoadingView.snp.makeConstraints { (maker) in
                maker.centerY.equalTo(tipLabel)
                maker.left.equalTo(tipLabel.snp.right)
                maker.width.height.equalTo(16)
            }
        }
        func start(with tip: String = "", withLoadingSyle style: SubtitleLoadingStyle) {
            tipLabel.attributedText = NSAttributedString(string: tip, config: .body)
            circleLoadingView.play()
            switch style {
            case .noNeed:
                circleLoadingView.isHidden = true
                dotLoadingView.isHidden = true
                circleLoadingView.removeFromSuperview()
                dotLoadingView.removeFromSuperview()
                tipLabel.snp.remakeConstraints { (maker) in
                    maker.center.equalToSuperview()
                    maker.width.equalTo(0).priority(.low)
                }
            case .circle:
                dotLoadingView.isHidden = true
                circleLoadingView.isHidden = false
                dotLoadingView.removeFromSuperview()
                circleLoadingView.removeFromSuperview()
                addSubview(circleLoadingView)
                circleLoadingView.snp.remakeConstraints { (maker) in
                    maker.left.equalToSuperview()
                    maker.centerY.equalToSuperview()
                    maker.width.height.equalTo(24)
                }
                tipLabel.snp.remakeConstraints { (maker) in
                    maker.centerY.equalTo(circleLoadingView)
                    maker.left.equalTo(circleLoadingView.snp.right).offset(8)
                    maker.right.lessThanOrEqualToSuperview()
                    maker.width.equalTo(0).priority(.low)
                }
                circleLoadingView.play()
            case .dot:
                circleLoadingView.isHidden = true
                dotLoadingView.isHidden = false
                circleLoadingView.removeFromSuperview()
                dotLoadingView.removeFromSuperview()
                addSubview(dotLoadingView)
                tipLabel.snp.remakeConstraints { (maker) in
                    maker.center.equalToSuperview()
                    maker.width.equalTo(0).priority(.low)
                }
                dotLoadingView.snp.remakeConstraints { (maker) in
                    maker.centerY.equalTo(tipLabel)
                    maker.left.equalTo(tipLabel.snp.right)
                    maker.width.height.equalTo(16)
                }
            }
        }
        func stop() {
            tipLabel.text = ""
            circleLoadingView.stop()
        }
    }
}

enum InMeetSubtitleDisplayType {
    case single
    case multiple
}

class InMeetSubtitleDataHandler {

    var speakers: [Speaker] = []

    var displayType = InMeetSubtitleDisplayType.single {
        didSet {
            if displayType != oldValue {
                layoutChangedBlock?()
            }
        }
    }

    var isShowAll: Bool {
        !speakers.contains { !$0.isShowAll() }
    }

    var layoutChangedBlock: (() -> Void)?

    init() {
    }

    func updateSubtitle(_ data: SubtitleViewData) {
        guard data.subtitle.data.event?.type != .turnSubtitleOn, !data.subtitle.isNoise else { return }
        var validSpeakers = getValidSpeakers(subtitle: data)
        var isNewSpeaker = true
        let count = validSpeakers.count
        for (i, speaker) in validSpeakers.enumerated() {
            if speaker.updateSubtitleIfNeeded(data) {
                isNewSpeaker = false
                break
            }
            if (speaker.isValid(with: data) || i == count - 1), speaker.appendSubtitleIfNeeded(data) {
                isNewSpeaker = false
                break
            }
        }
        if isNewSpeaker {
            let speaker = Speaker()
            speaker.appendSubtitleIfNeeded(data)
            validSpeakers.append(speaker)
        }
        displayType = validSpeakers.count > 1 ? .multiple : .single
        speakers = validSpeakers
    }

    func getValidSpeakers(subtitle: SubtitleViewData) -> [Speaker] {
        var validSpeakers: [Speaker] = []
        for (i, speaker) in speakers.reversed().enumerated() {
            if i < 2 {
                validSpeakers.insert(speaker, at: 0)
            }
        }
        if validSpeakers.count == 2 {
            if validSpeakers[1].lineCount > 1, validSpeakers[0].isShowAll() {
                validSpeakers.remove(at: 0)
                return validSpeakers
            }
            if validSpeakers[1].isShowAll(), !validSpeakers[0].isShowAll() {
                validSpeakers.removeLast()
            }
        }
        return validSpeakers
    }

    func removeAllData() {
        speakers = []
        displayType = .single
    }

    func updateWordEnd() {
        speakers.forEach { speaker in
            speaker.updateWordEnd()
        }
    }

    func removeInvalidSubtitlesIfNeeded() {
        speakers.forEach { speaker in
            speaker.removeInvalidSubtitlesIfNeeded()
        }
    }
}

extension InMeetSubtitleDataHandler {

    class Speaker {
        var identifier: String = ""
        var subtitles: [SubtitleViewData] = []
        var timestamp: CFTimeInterval = CACurrentMediaTime()
        var lineCount: Int = 0 {
            didSet {
                if lineCount != oldValue, lineCount > 3 {
                    removeInvalidSubtitlesIfNeeded()
                }
            }
        }

        @discardableResult
        func appendSubtitleIfNeeded(_ subtitle: SubtitleViewData) -> Bool {
            guard identifier == "" || identifier == subtitle.participantId.identifier else { return false }
            identifier = subtitle.participantId.identifier
            subtitles.append(subtitle)
            timestamp = CACurrentMediaTime()
            return true
        }

        @discardableResult
        func updateSubtitleIfNeeded(_ subtitle: SubtitleViewData) -> Bool {
            guard subtitle.participantId.identifier == identifier else { return false }
            let foundIndex = subtitles.firstIndex { [subtitle] (item) -> Bool in
                return item.subtitle.groupID == subtitle.subtitle.groupID
            }
            if let index = foundIndex {
                let old = subtitles[index]
                subtitle.currentWordEnd = old.currentWordEnd
                subtitles[index] = subtitle
            } else {
                return false
            }
            timestamp = CACurrentMediaTime()
            return true
        }

        func isValid(with subtitle: SubtitleViewData) -> Bool {
            guard subtitle.participantId.identifier == identifier else { return false }
            if subtitles.count == 0 { return true }
            let dur = Int(CACurrentMediaTime() - timestamp) * 1000
            return dur < 2000
        }

        func isShowAll() -> Bool {
            let dur = Int(CACurrentMediaTime() - timestamp) * 1000
            if dur > 20000 { return true }
            return !subtitles.contains(where: { !$0.isShowAll })
        }

        func updateWordEnd() {
            subtitles.forEach { item in
                item.updateWordEnd()
            }
        }

        func removeInvalidSubtitlesIfNeeded() {
            let count = subtitles.count
            let maxCount = getMaxCount()
            guard count >= maxCount else { return }
            let valid = subtitles.suffix(maxCount)
            subtitles = Array(valid)
        }

        func getMaxCount() -> Int {
            var count = 0
            for (i, data) in subtitles.reversed().enumerated() {
                count += data.lineCount
                if count > 3 {
                    return i + 1
                }
            }
            return 3
        }
    }
}
