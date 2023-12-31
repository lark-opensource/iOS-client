//
//  EventFeedHeaderView.swift
//  LarkFeed
//
//  Created by xiaruzhen on 1822/9/26.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import RxCocoa
import LarkOpenFeed
import EENavigator
import LarkTag

final class EventFeedHeaderView: UIView {

    private let disposeBag = DisposeBag()
    let viewModel: EventFeedHeaderViewModel
    let contentView = UIView()
    let leftAreaView = UIView()
    let rightAreaView = UIStackView()

    let icon = UIImageView()
    let statusLabel = UILabel()
    let titleLabel = UILabel()
    let tagStackView = TagWrapperView()
    let closeImageView = UIImageView()
    let numberLabel = UILabel()
    let moreImageView = UIImageView()

    init(viewModel: EventFeedHeaderViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setupViews()
        render()
        bind()
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    private func setupViews() {
        self.backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.fillSelected
        contentView.layer.cornerRadius = 6
        contentView.clipsToBounds = true
        let font = UIFont.systemFont(ofSize: 14, weight: .medium)
        statusLabel.font = font
        statusLabel.textColor = UIColor.ud.textTitle
        titleLabel.textColor = UIColor.ud.colorfulBlue
        titleLabel.font = font
        closeImageView.image = self.viewModel.viewData?.closeImage
        numberLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        numberLabel.textColor = UIColor.ud.textCaption
        moreImageView.image = self.viewModel.viewData?.moreImage
        let leftViewTap = UITapGestureRecognizer(target: self, action: #selector(lookDetailAction))
        leftAreaView.addGestureRecognizer(leftViewTap)
        let rightViewTap = UITapGestureRecognizer(target: self, action: #selector(rightViewAction))
        rightAreaView.addGestureRecognizer(rightViewTap)
        rightAreaView.axis = .horizontal
        rightAreaView.alignment = .center
        rightAreaView.distribution = .equalCentering
        rightAreaView.spacing = 5
        //rightAreaView.setCustomSpacing(5, after: view)
        self.addSubview(contentView)
        contentView.addSubview(leftAreaView)
        contentView.addSubview(rightAreaView)
        leftAreaView.addSubview(icon)
        leftAreaView.addSubview(statusLabel)
        leftAreaView.addSubview(titleLabel)
        leftAreaView.addSubview(tagStackView)
        rightAreaView.addArrangedSubview(closeImageView)
        rightAreaView.addArrangedSubview(numberLabel)
        rightAreaView.addArrangedSubview(moreImageView)

        contentView.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.top.equalToSuperview().offset(4)
            make.bottom.equalToSuperview().offset(-4)
        }

        leftAreaView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        leftAreaView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        leftAreaView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        statusLabel.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }

        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(statusLabel.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }

        tagStackView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        tagStackView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        tagStackView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(5)
            make.height.equalTo(18)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }

        rightAreaView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        rightAreaView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        rightAreaView.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(leftAreaView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.top.bottom.equalToSuperview()
        }

        closeImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }

        numberLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        numberLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        moreImageView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 20, height: 20))
        }
    }

    private func bind() {
        viewModel.renderObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.render()
        }).disposed(by: disposeBag)
    }

    private func render() {
        self.icon.image = self.viewModel.viewData?.icon
        self.statusLabel.text = self.viewModel.viewData?.status
        self.titleLabel.text = self.viewModel.viewData?.title
        self.numberLabel.text = self.viewModel.viewData?.numberTitle
        if self.viewModel.viewData?.moreMode ?? false {
            self.closeImageView.isHidden = true
            self.numberLabel.isHidden = false
            self.moreImageView.isHidden = false
        } else {
            self.closeImageView.isHidden = false
            self.numberLabel.isHidden = true
            self.moreImageView.isHidden = true
        }
        if let tags = self.viewModel.viewData?.tags, !tags.isEmpty {
            tagStackView.isHidden = false
            tagStackView.set(tags: tags)
        } else {
            tagStackView.isHidden = true
            tagStackView.set(tags: [])
        }
    }

    @objc
    func lookDetailAction() {
        guard let item = self.viewModel.viewData?.item else { return }
        EventTracker.Feed.Click.Title(eventId: item.id, type: item.biz.rawValue)
        self.viewModel.tap(item: item)
    }

    @objc
    func rightViewAction() {
        if self.viewModel.viewData?.moreMode ?? false {
            moreAction()
        } else {
            closeAction()
        }
    }

    func moreAction() {
        let context = try? viewModel.userResolver.resolve(assert: FeedContextService.self)
        guard let page = context?.page else { return }
        guard let item = self.viewModel.viewData?.item else { return }
        EventTracker.Feed.Click.EnterList(eventId: item.id, type: item.biz.rawValue)
        let body = EventListBody()
        viewModel.userResolver.navigator.present(body: body,
                                                 wrap: LkNavigationController.self,
                                                 from: page,
                                                 animated: true)
    }

    func closeAction() {
        guard let item = self.viewModel.viewData?.item else { return }
        EventTracker.Feed.Click.Close(eventId: item.id, type: item.biz.rawValue)
        self.viewModel.fillter(item: item)
    }
}
