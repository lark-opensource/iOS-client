//
//  MailSearchHistoryBottomView.swift
//  Action
//
//  Created by tefeng liu on 2019/7/30.
//

import UIKit
import RxSwift
import SnapKit
import UniverseDesignIcon
import UniverseDesignTag

protocol MailSearchQueryBottomViewDelegate: AnyObject {
    func bottomViewDidClickClearHistory(_ bottomView: MailSearchQueryBottomView)
    func bottomView(_ bottomView: MailSearchQueryBottomView, didSelect historyInfo: MailSearchHistoryInfo)
}

class MailSearchQueryBottomView: UIView {
    weak var delegate: MailSearchQueryBottomViewDelegate?

    var historyInfos = [MailSearchHistoryInfo]()
    private var historyButtons: [MailSearchHistoryItem] = []
    private let titleLabel = UILabel()
    private let clearButton = UIButton()
    private let historyInfoView = UIButton()

    private let testButton = UIButton()
    private let disposeBag = DisposeBag()

    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor.ud.bgBody

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        // TODO: search
        titleLabel.text = BundleI18n.MailSDK.Mail_Search_SearchHistory
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.height.equalTo(20)
        }

        clearButton.setImage(UDIcon.deleteTrashOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        clearButton.tintColor = UIColor.ud.iconN2
        addSubview(clearButton)
        clearButton.snp.makeConstraints { (make) in
            make.right.equalTo(-16)
            make.centerY.equalTo(titleLabel)
            make.width.height.equalTo(16)
        }
        clearButton.rx.tap
            .subscribe(onNext: { [weak self] () in
                guard let `self` = self else { return }
                self.delegate?.bottomViewDidClickClearHistory(self)
            })
            .disposed(by: disposeBag)

        addSubview(historyInfoView)
        historyInfoView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.bottom.equalToSuperview()
        }
    }

    @objc
    func backgroundTapHandler() {
        self.delegate?.bottomViewDidClickClearHistory(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(historyInfos: [MailSearchHistoryInfo]) {
        self.historyInfos = historyInfos
        historyButtons.forEach { $0.removeFromSuperview() }
        historyButtons.removeAll()

        let labelFrames = calcLabelFrames(lastCharRect: CGRect(origin: bounds.origin, size: CGSize(width: 1, height: 28)),
                                          textContainerWidth: bounds.width - 32,
                                          textContentRect: CGRect(origin: bounds.origin,
                                                                  size: CGSize(width: bounds.width - 32, height: 1)),
                                          filteredLabels: historyInfos.map({ $0.keyword }))

        for (index, info) in historyInfos.enumerated() where index < labelFrames.count {
            let tag = MailSearchHistoryItem(info: info, text: info.keyword, isLTR: true,
                                            textColor: UIColor.ud.textTitle,
                                            backgroundColor: UIColor.ud.udtokenTagNeutralTextNormal.withAlphaComponent(0.1))
            tag.didClickSearchHistoryInfoBlock = { [weak self] info in
                guard let `self` = self else { return }
                self.delegate?.bottomView(self, didSelect: info)
            }
            tag.tag = index
            tag.frame = labelFrames[index]
            historyButtons.append(tag)
            historyInfoView.addSubview(tag)
        }
    }

//    @objc
//    func tagTapped(_ ges: UITapGestureRecognizer) {
//        delegate?.titleLabelsTapped()
//    }

    /// 计算labels布局frames
    private func calcLabelFrames(lastCharRect: CGRect, textContainerWidth: CGFloat, textContentRect: CGRect, filteredLabels: [String]) -> [CGRect] {
        let padding: CGFloat = 12
        var posMinX: CGFloat = 0
        var posMaxY = padding

        var labelFrames = [CGRect]()
        for label in filteredLabels {
            let tagSize = MailSearchHistoryItem.sizeThatFit(text: label, isLTR: true)
            // tag最大宽度为label宽度
            let tagWidth = min(tagSize.width + 1, textContainerWidth)
            let tagHeight = tagSize.height

            // 判断label当前行是否有足够的位置，有的话，继续放，没有的话下一行
            let remainWidth = textContainerWidth - posMinX
            if remainWidth < tagWidth {
                posMinX = textContentRect.minX
                posMaxY = posMaxY + lastCharRect.height + padding
            }
            let tagFrame = CGRect(x: posMinX, y: posMaxY, width: tagWidth, height: tagHeight)
            labelFrames.append(tagFrame)
            posMinX = posMinX + tagWidth + padding
        }
        return labelFrames
    }
}

class MailSearchHistoryItem: UIButton {
    private let udTag: UDTag
    private let tagBackgroundColor: UIColor
    private let info: MailSearchHistoryInfo

    var text: String? {
        return udTag.text
    }

    var didClickSearchHistoryInfoBlock: ((MailSearchHistoryInfo) -> Void)?

    init(info: MailSearchHistoryInfo, text: String, isLTR: Bool, textColor: UIColor, backgroundColor: UIColor) {
        self.info = info
        let udTagConfig = MailSearchHistoryItem.tagConfig(text: text, isLTR: isLTR, textColor: textColor, bgColor: backgroundColor)
        self.udTag = UDTag(text: text, textConfig: udTagConfig)
        self.tagBackgroundColor = backgroundColor
        super.init(frame: .zero)

        udTag.isUserInteractionEnabled = false
        addSubview(udTag)
        udTag.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.isUserInteractionEnabled = true
        addTarget(self, action: #selector(btnTapped), for: .touchUpInside)
    }

    @objc
    private func btnTapped() {
        didClickSearchHistoryInfoBlock?(info)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var desiredSize: CGSize {
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        return UDTag.sizeToFit(config: udTag.config, title: udTag.text, containerSize: maxSize)
    }

    static func tagConfig(text: String, isLTR: Bool, textColor: UIColor, bgColor: UIColor) -> UDTagConfig.TextConfig {
        return UDTagConfig.TextConfig(padding: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8),
                                      font: UIFont.systemFont(ofSize: 14),
                                      cornerRadius: 14,
                                      textAlignment: isLTR ? .left : .right,
                                      textColor: textColor,
                                      backgroundColor: bgColor,
                                      height: 28,
                                      maxLenth: nil)
    }

    static func sizeThatFit(text: String, isLTR: Bool) -> CGSize {
        let maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let tagConfig = tagConfig(text: text, isLTR: isLTR, textColor: .black, bgColor: .black)
        return UDTag.sizeToFit(config: .text(tagConfig), title: text, containerSize: maxSize)
    }
}
