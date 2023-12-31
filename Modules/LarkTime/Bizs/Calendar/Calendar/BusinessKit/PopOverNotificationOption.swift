//
//  PopOverNotificationOption.swift
//  Calendar
//
//  Created by yantao on 2019/12/29.
//

import UIKit
import Foundation
import CalendarFoundation
import SnapKit

final class PopOverNotificationOption: UIViewController {

    private let stackView = UIStackView()

    init(sourceView: UIView,
         sourceRect: CGRect,
         arrowDirection: UIPopoverArrowDirection,
         delegate: UIPopoverPresentationControllerDelegate?) {
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .popover
        self.popoverPresentationController?.sourceView = sourceView
        self.popoverPresentationController?.canOverlapSourceViewRect = false
        self.popoverPresentationController?.sourceRect = sourceRect
        self.popoverPresentationController?.permittedArrowDirections = arrowDirection
        self.popoverPresentationController?.delegate = delegate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addItem(title: String, tapAction: @escaping () -> Void) {
        let cell = PopOverNotificationOptionCell(title: title, tapAction: { [weak self] in
            self?.dismiss(animated: true) {
                tapAction()
            }
        })
        if !stackView.arrangedSubviews.isEmpty {
            stackView.addArrangedSubview(Line())
        }
        stackView.addArrangedSubview(cell)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.ud.bgBody
        self.view.addSubview(stackView)
        stackView.axis = .vertical
        stackView.snp.makeConstraints { (make) in
            make.center.equalTo(view.safeAreaLayoutGuide)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize = stackView.bounds.size
    }
}

final class PopOverNotificationOptionCell: UIView {
    private let titleLable: UILabel = {
        let label = UILabel.cd.titleLabel(fontSize: 16)
        return label
    }()

    private let button: UIButton = UIButton()
    private let action: () -> Void

    init(title: String, tapAction: @escaping () -> Void) {
        action = tapAction
        super.init(frame: .zero)
        titleLable.text = title

        self.addSubview(titleLable)
        titleLable.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualToSuperview().offset(24)
            make.right.lessThanOrEqualTo(self.snp.right).offset(-24)
            make.center.equalToSuperview()
        }

        addSubview(button)
        button.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        button.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        self.snp.makeConstraints { (make) in
            make.height.equalTo(56)
            make.width.greaterThanOrEqualTo(375)
        }
    }

    @objc
    private func tapped() {
        action()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class Line: UIView {
    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.commonTableSeparatorColor
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 1.0 / UIScreen.main.scale
        return size
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
