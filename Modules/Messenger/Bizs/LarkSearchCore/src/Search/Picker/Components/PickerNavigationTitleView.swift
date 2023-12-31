//
//  PickerNavigationTitleView.swift
//  LarkSearchCore
//
//  Created by 赵家琛 on 2021/2/3.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkUIKit
import RxSwift

public final class PickerNavigationTitleView: UIView {
    private lazy var contentStatckView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .center
        return titleLabel
    }()

    private lazy var subTitleLabel: UILabel = {
        let subTitleLabel = UILabel()
        subTitleLabel.font = UIFont.systemFont(ofSize: 11)
        subTitleLabel.textColor = UIColor.ud.textCaption
        subTitleLabel.adjustsFontSizeToFitWidth = true
        subTitleLabel.minimumScaleFactor = 0.8
        return subTitleLabel
    }()

    private let disposeBag = DisposeBag()

    public init(title: String,
                observable: Observable<[Option]>,
                initialValue: [Option],
                shouldDisplayCountTitle: Bool = true) {
        super.init(frame: .zero)

        self.titleLabel.text = title
        self.addSubview(contentStatckView)
        contentStatckView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentStatckView.addArrangedSubview(titleLabel)

        if shouldDisplayCountTitle {
            contentStatckView.addArrangedSubview(subTitleLabel)
            self.syncView(options: initialValue)
            startObserve(observable)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startObserve(_ observable: Observable<[Option]>) {
        observable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (options) in
                guard let self = self else { return }
                self.syncView(options: options)
            }).disposed(by: self.disposeBag)
    }

    private func syncView(options: [Option]) {
        var chatterCount = 0
        var chatCount = 0
        var departmentCount = 0
        var userGroupCount = 0
        for opt in options {
            let type = opt.optionIdentifier.type
            switch type {
            case OptionIdentifier.Types.chatter.rawValue:
                chatterCount += 1
            case OptionIdentifier.Types.chat.rawValue:
                chatCount += 1
            case OptionIdentifier.Types.department.rawValue:
                departmentCount += 1
            case OptionIdentifier.Types.userGroup.rawValue, OptionIdentifier.Types.userGroupAssign.rawValue, OptionIdentifier.Types.newUserGroup.rawValue:
                userGroupCount += 1
            case OptionIdentifier.Types.bot.rawValue:
                continue
            default:
                assertionFailure("not supported option type \(opt), for show on navigation title view")
                break
            }
        }

        var subtitle = ""
        if chatterCount != 0 {
            subtitle += BundleI18n.LarkSearchCore.Lark_Groups_MobileSelectedCountMembers(chatterCount)
        }
        if chatCount != 0 {
            subtitle += BundleI18n.LarkSearchCore.Lark_Legacy_NumberChatsICU(chatCount)
        }
        if departmentCount != 0 {
            subtitle += BundleI18n.LarkSearchCore.Lark_Legacy_NumberOrganizations(departmentCount)
        }
        if userGroupCount != 0 {
            subtitle += BundleI18n.LarkSearchCore.Lark_IM_Picker_UserGroupNum_Text(userGroupCount)
        }
        self.subTitleLabel.text = subtitle
    }
}
