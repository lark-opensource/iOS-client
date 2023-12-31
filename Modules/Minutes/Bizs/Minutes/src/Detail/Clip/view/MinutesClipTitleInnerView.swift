//
//  MinutesClipTitleInnerView.swift
//  Minutes
//
//  Created by admin on 2022/5/14.
//
import UIKit
import UniverseDesignColor
import MinutesFoundation
import RichLabel

class MinutesClipTitleInnerView: UIView {

    var text: String = "" {
        didSet {
            layout(withText: text)
        }
    }

    var viewHeight: CGFloat = 0

    var preferredMaxLayoutWidth: CGFloat = 0

    private lazy var label1: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.lineBreakMode = .byClipping
        label.clipsToBounds = false
        return label
    }()

    private lazy var label2: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 17, weight: .medium)
        return label
    }()

    private lazy var tag1: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .medium)
        l.textColor = UIColor.ud.udtokenTagTextSPurple
        l.backgroundColor = UIColor.ud.udtokenTagBgPurple.withAlphaComponent(0.2)
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.text = " \(BundleI18n.Minutes.MMWeb_G_Clip) "
        return l
    }()

    private lazy var tag2: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .medium)
        l.textColor = UIColor.ud.udtokenTagTextSPurple
        l.backgroundColor = UIColor.ud.udtokenTagBgPurple.withAlphaComponent(0.2)
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.text = " \(BundleI18n.Minutes.MMWeb_G_Clip) "
        return l
    }()

    private lazy var stack1: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.addArrangedSubview(label1)
        stackView.setCustomSpacing(6, after: label1)
        stackView.addArrangedSubview(tag1)
        tag1.snp.makeConstraints { make in
            make.height.equalTo(16)
        }
        return stackView
    }()

    private lazy var stack2: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.addArrangedSubview(label2)
        stackView.setCustomSpacing(6, after: label2)
        stackView.addArrangedSubview(tag2)
        tag2.snp.makeConstraints { make in
            make.height.equalTo(16)
        }
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.addArrangedSubview(stack1)
        stack1.snp.makeConstraints { make in
            make.height.equalTo(24)
        }
        stackView.addArrangedSubview(stack2)
        stack2.snp.makeConstraints { make in
            make.height.equalTo(24)
        }
        return stackView
    }()

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tag1.sizeToFit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout(withText text: String) {
        let tagWidth = tag1.bounds.width
        let attributedStr = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 17)])
        let layout = LKTextLayoutEngineImpl()
        layout.attributedText = attributedStr
        layout.preferMaxWidth = preferredMaxLayoutWidth - tagWidth - 4
        layout.layout(size: CGSize(width: preferredMaxLayoutWidth - tagWidth - 4, height: CGFloat.greatestFiniteMagnitude))
        if layout.lines.count > 1 {
            let layout = LKTextLayoutEngineImpl()
            layout.attributedText = attributedStr
            layout.preferMaxWidth = preferredMaxLayoutWidth - 4
            layout.layout(size: CGSize(width: preferredMaxLayoutWidth - 4, height: CGFloat.greatestFiniteMagnitude))
            let lines = layout.lines
            label1.text = (text as NSString).substring(with: NSRange(location: lines[0].range.location, length: lines[0].range.length))
            if lines.count > 1 {
                label2.text = (text as NSString).substring(with: NSRange(location: lines[1].range.location, length: lines[1].range.length))
                label2.isHidden = false
            } else {
                label2.isHidden = true
            }
            tag1.isHidden = true
            tag2.isHidden = false
            stack2.isHidden = false
            viewHeight = 24 * 2
        } else {
            stack2.isHidden = true
            label1.text = text
            tag1.isHidden = false
            viewHeight = 24
        }
    }

}
