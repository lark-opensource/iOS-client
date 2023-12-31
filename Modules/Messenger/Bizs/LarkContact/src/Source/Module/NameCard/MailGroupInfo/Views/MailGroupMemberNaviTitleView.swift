//
//  MailGroupMemberNaviTitleView.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/11/18.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift

public final class MailGroupMemberNaviTitleView: UIView {
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
                observable: Observable<Int>,
                shouldDisplayCountTitle: Bool = true) {
        super.init(frame: .zero)

        self.titleLabel.text = title
        self.addSubview(contentStatckView)
        contentStatckView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentStatckView.addArrangedSubview(titleLabel)

        if shouldDisplayCountTitle {
            contentStatckView.addArrangedSubview(subTitleLabel)
            self.syncView(count: 0)
        }
        startObserve(observable)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startObserve(_ observable: Observable<Int>) {
        observable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (count) in
                guard let self = self else { return }
                self.syncView(count: count)
            }).disposed(by: self.disposeBag)
    }
    // swiftlint:disable empty_count
    private func syncView(count: Int) {
        var subtitle = count > 0 ? BundleI18n.LarkContact.Mail_MailingList_SelectedNumPeople(count) : ""
        self.subTitleLabel.text = subtitle
    }
    // swiftlint:enable empty_count
}
