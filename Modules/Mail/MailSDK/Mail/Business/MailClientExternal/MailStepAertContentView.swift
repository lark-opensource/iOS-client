//
//  MailImapLoginFailedView.swift
//  MailSDK
//
//  Created by Quanze Gao on 2023/4/4.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon

struct MailStepAlertContent {
    typealias AlertStep = (content: String, actionText: String?, action: (() -> Void)?)
    let title: String
    let steps: [AlertStep]
}

class MailStepAlertContentView: UIView {
    var pagetType: String = "others"
    private let dataSource: MailStepAlertContent
    init(dataSource: MailStepAlertContent) {
        self.dataSource = dataSource
        super.init(frame: .zero)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        self.dataSource = MailStepAlertContent(title: "", steps: [])
        super.init(coder: aDecoder)
    }
    
    private func setupViews() {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        let titleLabelParagraph = NSMutableParagraphStyle()
        titleLabelParagraph.lineSpacing = 3
        // BundleI18n.MailSDK.Mail_LinkAccount_AdvancedSetting_UnableToLogIn_Desc
        titleLabel.attributedText = NSAttributedString(
            string: dataSource.title,
            attributes: [
                .foregroundColor: UIColor.ud.textTitle,
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: titleLabelParagraph
            ])
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(2)
        }
        
        let container = UIView()
        container.backgroundColor = .ud.bgBase
        container.layer.cornerRadius = 6
        addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview()
        }
        var stepNum = 1
        var lastContent: UIView?
        for step in dataSource.steps {
            let content = makeContent(number: stepNum, content: step.content, actionText: step.actionText, action: step.action)
            container.addSubview(content)
            content.snp.makeConstraints { make in
                make.left.right.equalToSuperview().inset(16)
                if let lastContent = lastContent {
                    make.top.equalTo(lastContent.snp.bottom).offset(16)
                } else {
                    make.top.equalToSuperview().inset(16)
                }
                if stepNum == dataSource.steps.count {
                    make.bottom.equalToSuperview().inset(16)
                }
            }
            lastContent = content
            stepNum += 1
        }
    }
}

private extension MailStepAlertContentView {
    func makeContent(number: Int, content: String, actionText: String?, action: (() -> Void)?) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        
        let numberView = makeNumberView(number)
        container.addSubview(numberView)
        numberView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview().inset(2)
            make.width.height.equalTo(16)
        }

        let contentLabel = UILabel()
        contentLabel.numberOfLines = 0
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 3
        contentLabel.attributedText = NSAttributedString(
            string: content,
            attributes: [
                .foregroundColor: UIColor.ud.textTitle,
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .paragraphStyle: paragraph
            ])
        container.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.left.equalTo(numberView.snp.right).offset(8)
            make.right.equalToSuperview()
            make.top.equalTo(numberView.snp.top).offset(number == 3 ? 0 : -1)
            if actionText == nil {
                make.bottom.equalToSuperview()
            }
        }
        
        if let actionText = actionText {
            let textView = ActionableTextView()
            textView.font = .systemFont(ofSize: 14)
            textView.text = actionText
            textView.action = action
            textView.actionableText = actionText
            textView.updateAttributes()
            textView.textContainerInset = .zero
            textView.textContainer.lineFragmentPadding = 0
            textView.backgroundColor = .clear
            textView.isScrollEnabled = false
            container.addSubview(textView)
            textView.snp.makeConstraints { make in
                make.left.equalTo(contentLabel.snp.left)
                make.top.equalTo(contentLabel.snp.bottom).offset(6)
                make.bottom.equalToSuperview()
            }
            
            let arrowButton = UIButton()
            arrowButton.tintColor = .ud.primaryContentDefault
            arrowButton.setImage(UDIcon.rightOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
            arrowButton.addAction {
                action?()
            }
            container.addSubview(arrowButton)
            arrowButton.snp.makeConstraints { make in
                make.left.equalTo(textView.snp.right)
                make.width.height.equalTo(14)
                make.centerY.equalTo(textView.snp.centerY)
            }
        }
        
        return container
    }
    
    func makeNumberView(_ number: Int) -> UIView {
        let button = UIButton()
        button.setTitle("\(number)", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.layer.cornerRadius = 8
        button.backgroundColor = .ud.primaryContentDefault
        button.isUserInteractionEnabled = false
        return button
    }
}


