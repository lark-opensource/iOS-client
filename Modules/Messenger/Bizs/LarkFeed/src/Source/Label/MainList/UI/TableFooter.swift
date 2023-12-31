//
//  TableFooter.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/25.
//

import Foundation
import UIKit

protocol LabelTableFooterDelegate: AnyObject {
    func click()
}

final class LabelTableFooter: UIView {

    var actionHandlerAdapter: LabelMainListActionHandlerAdapter?
    var viewModel: LabelViewModel?

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let separatorView = UIView()
    var display = false
    let title: String
    weak var delegate: LabelTableFooterDelegate?

    init(title: String) {
        self.title = title
        super.init(frame: .zero)
        self.setupView()
        self.layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setActionHandlerAdapter(_ actionHandlerAdapter: LabelMainListActionHandlerAdapter) {
        self.actionHandlerAdapter = actionHandlerAdapter
    }

    @objc
    private func tapAction() {
        if let delegate = delegate {
            delegate.click()
        } else {
            FeedTracker.Label.Click.CreatLabelInFooter()
            actionHandlerAdapter?.creatLabel()
        }
    }

    private func setupView() {
        self.clipsToBounds = true
        self.backgroundColor = UIColor.ud.bgBody
        imageView.image = Resources.addMiddleOutlined
        titleLabel.text = title
        titleLabel.textColor = UIColor.ud.textCaption
        titleLabel.font = UIFont.ud.title4
        separatorView.backgroundColor = UIColor.ud.lineDividerDefault

        let tapGes = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.addGestureRecognizer(tapGes)
    }

    private func layout() {
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(separatorView)

        imageView.snp.makeConstraints { (make) in
            make.size.equalTo(18)
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(5)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-16)
        }

        separatorView.snp.makeConstraints { (make) in
            make.trailing.bottom.equalToSuperview()
            make.leading.equalTo(imageView)
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }
}
