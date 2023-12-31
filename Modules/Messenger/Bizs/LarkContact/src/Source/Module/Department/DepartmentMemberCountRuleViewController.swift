//
//  DepartmentMemberCountRuleViewController.swift
//  LarkContact
//
//  Created by Nix Wang on 2023/1/31.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignColor
import UniverseDesignFont
import LKCommonsLogging
import LarkContainer
import UniverseDesignTheme

class DepartmentMemberCountRuleViewController: UIViewController {
    static let logger = Logger.log(DepartmentMemberCountRuleViewController.self, category: "Contact.DepartmentMemberCountRuleViewController")

    private let isShowDepartmentPrimaryMemberCount: Bool
    private let contactDataDependency: ContactDataDependency

    private lazy var gradientBackgroundView: UIImageView = {
        let view = UIImageView()
        view.image = Resources.gradient_background
        view.contentMode = .scaleAspectFill
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .ud.textTitle
        label.font = .ud.body0.withWeight(.semibold)
        label.text = BundleI18n.LarkContact.SuiteAdmin_ORMTotal_Tooltip_CurrentDepartmentMemberSetTo
        return label
    }()

    private lazy var ruleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .ud.textTitle
        label.font = .ud.body0
        return label
    }()

    private let imageView = UIImageView()

    init(isShowDepartmentPrimaryMemberCount: Bool, contactDataDependency: ContactDataDependency) {
        self.isShowDepartmentPrimaryMemberCount = isShowDepartmentPrimaryMemberCount
        self.contactDataDependency = contactDataDependency

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = BundleI18n.LarkContact.SuiteAdmin_ORMTotal_Tooltip_DepartmentMemberInstruction
        view.backgroundColor = UIColor.ud.bgBody

        view.addSubview(gradientBackgroundView)
        gradientBackgroundView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(gradientBackgroundView.snp.width).multipliedBy(120.0 / 335.0)
        }

        if isShowDepartmentPrimaryMemberCount {
            ruleLabel.text = BundleI18n.LarkContact.Lark_ORMTotal_Tooltip_OnlyMainDepartmentWhenMore
        } else {
            ruleLabel.text = BundleI18n.LarkContact.Lark_ORMTotal_Tooltip_RecountAllDepartments
        }
        let ruleStack = UIStackView(arrangedSubviews: [titleLabel, ruleLabel])
        ruleStack.axis = .vertical
        ruleStack.spacing = 4
        view.addSubview(ruleStack)
        ruleStack.snp.makeConstraints { make in
            make.top.equalTo(48)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualTo(400).priority(.required)
            make.width.equalToSuperview().offset(-48).priority(.high)
        }

        imageView.contentMode = .scaleAspectFit
        imageView.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .horizontal)
        imageView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 249), for: .horizontal)
        imageView.setContentHuggingPriority(UILayoutPriority(rawValue: 249), for: .vertical)
        imageView.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 249), for: .vertical)
        view.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.width.equalTo(ruleStack.snp.width)
            make.height.equalTo(imageView.snp.width).multipliedBy(393.0 / 327.0)
            make.centerX.equalToSuperview()
            make.top.equalTo(ruleStack.snp.bottom).offset(48)
        }

        updateImage()
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(self, selector: #selector(updateImage), name: UDThemeManager.didChangeNotification, object: nil)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateImage()
    }

    @objc
    private func updateImage() {
        if let url = contactDataDependency.memberCountRuleImageURL() {
            imageView.kf.setImage(with: url)
        }
    }

}
