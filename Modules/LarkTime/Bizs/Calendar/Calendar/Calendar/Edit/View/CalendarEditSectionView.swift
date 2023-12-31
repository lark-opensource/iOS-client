//
//  CalendarEditSectionView.swift
//  Calendar
//
//  Created by Hongbin Liang on 3/22/23.
//

import Foundation
import UIKit

class CalendarEditSectionView: UIStackView {

    init(title: String? = nil) {
        super.init(frame: .zero)
        setupViews()

        titleLabel.text = title
    }

    /// 垂直方向重新填充 views，会清空原有内容
    /// - Parameters:
    ///   - contents: 自撑
    ///   - footer: footer text
    ///   - isButtonSection: 用于判断分割线是否通栏
    func reFillWith(contents: [UIView], footer: String? = nil, isButtonSection: Bool = false) {
        containerStack.clearSubviews()

        let contentsNum = contents.count
        guard contentsNum > 0 else {
            isHidden = true
            return
        }
        isHidden = false

        contents.enumerated().forEach { index, content in
            containerStack.addArrangedSubview(content)
            if index < contentsNum - 1 {
                let separator = UIView()
                separator.backgroundColor = .ud.lineDividerDefault
                let wrapper = UIView()
                wrapper.addSubview(separator)
                let leftInset = isButtonSection ? 0 : 16
                separator.snp.makeConstraints { make in
                    make.leading.equalToSuperview().inset(leftInset)
                    make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
                    make.trailing.top.bottom.equalToSuperview()
                }
                containerStack.addArrangedSubview(wrapper)
            }
        }

        footerWrapper.isHidden = footer.isEmpty
        footerLabel.text = footer
    }

    private let titleLabel = UILabel()
    private let containerStack = UIStackView()
    private let footerWrapper = UIView()
    private let footerLabel = UILabel.cd.subTitleLabel()

    private func setupViews() {
        axis = .vertical
        spacing = 6

        titleLabel.textColor = .ud.textCaption
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        let labelContainer = UIView()
        labelContainer.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
        }
        addArrangedSubview(labelContainer)

        containerStack.axis = .vertical
        containerStack.backgroundColor = .ud.panelBgColor
        containerStack.layer.cornerRadius = 10
        containerStack.clipsToBounds = true
        addArrangedSubview(containerStack)

        footerWrapper.addSubview(footerLabel)
        footerLabel.numberOfLines = 0
        footerLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
        }
        addArrangedSubview(footerWrapper)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
