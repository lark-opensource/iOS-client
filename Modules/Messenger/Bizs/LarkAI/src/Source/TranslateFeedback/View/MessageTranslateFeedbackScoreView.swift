//
//  MessageTranslateFeedBackStarView.swift
//  LarkChat
//
//  Created by bytedance on 2020/8/25.
//

import Foundation
import UIKit
import LarkCore
import LarkModel
protocol MessageTranslateFeedbackScoreViewDelegate: AnyObject {
    /// 分数的回调
    func userChooseScore(score: Int)
}

private struct UI {
    static let layoutGuideWidth: CGFloat = 303
    /// star view
    static let contentViewHeight: CGFloat = 36
    static let contentViewWidth: CGFloat = 228
}

final class MessageTranslateFeedbackScoreView: UIView, LKStarRateViewDelegate {
    /// 分数
    private var score: Int = 0
    private var isSelectMode: Bool = false
    private var targetLanguage: String?
    private weak var delegate: MessageTranslateFeedbackScoreViewDelegate?
    private var trackParam: [String: Any] = [:]
    /// 星星视图
    private lazy var starView: LKStarRateView = {
        let starView = LKStarRateView(frame: CGRect(x: 0,
                                                    y: 0,
                                                    width: UI.contentViewWidth,
                                                    height: UI.contentViewHeight),
                                      config: LKStarRateViewConfig())
        starView.delegate = self
        return starView
    }()
    /// 描述文字
    private lazy var descLabel: UILabel = {
        let descLabel: UILabel = UILabel()
        descLabel.font = UIFont.systemFont(ofSize: 14)
        descLabel.textColor = UIColor.ud.textCaption
        descLabel.text = BundleI18n.LarkAI.Lark_Chat_TranslationFeedbackFiveStarsGuide

        return descLabel
    }()

    public init(score: Int,
                delegate: MessageTranslateFeedbackScoreViewDelegate,
                isSelectMode: Bool = false,
                targetLanguage: String? = nil,
                trackParam: [String: Any] = [:]) {
        self.score = score
        self.targetLanguage = targetLanguage
        self.delegate = delegate
        self.isSelectMode = isSelectMode
        self.trackParam = trackParam
        super.init(frame: CGRect.zero)
        setupSubViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubViews() {
        addSubview(starView)
        starView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(14)
            make.size.equalTo(CGSize(width: UI.contentViewWidth, height: UI.contentViewHeight))
        }
        addSubview(descLabel)
        descLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    // MARK: AppRatingStarViewDelegate
    func starRate(view starRateView: LKStarRateView, count score: Float) {
        /// 根据分数更新描述文案
        switch Int(score) {
        case 1:
            descLabel.text = BundleI18n.LarkAI.Lark_Chat_TranslationFeedbackOneStar
        case 2:
            descLabel.text = BundleI18n.LarkAI.Lark_Chat_TranslationFeedbackTwoStars
        case 3:
            descLabel.text = BundleI18n.LarkAI.Lark_Chat_TranslationFeedbackThreeStars
        case 4:
            descLabel.text = BundleI18n.LarkAI.Lark_Chat_TranslationFeedbackFourStars
        case 5:
            descLabel.text = BundleI18n.LarkAI.Lark_Chat_TranslationFeedbackFiveStarsDesc
        default:
            descLabel.text = BundleI18n.LarkAI.Lark_Chat_TranslationFeedbackFiveStarsGuide
        }
        MessageTranslateFeedbackTracker.translateFeedbackClick(messageID: trackParam["messageID"],
                                                               messageType: trackParam["messageType"],
                                                               srcLanguage: trackParam["srcLanguage"],
                                                               trgLanguage: trackParam["trgLanguage"],
                                                               cardSource: trackParam["cardSource"],
                                                               fromType: trackParam["fromType"],
                                                               clickType: "input",
                                                               extraParam: ["target": "rate"])
        /// 回调给vc分数
        delegate?.userChooseScore(score: Int(score))
    }

}
