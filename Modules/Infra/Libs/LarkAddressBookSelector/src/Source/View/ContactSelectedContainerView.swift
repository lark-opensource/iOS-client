//
//  ContactSelectedContainerView.swift
//  LarkAddressBookSelector
//
//  Created by zhenning on 2020/4/26.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import LKCommonsLogging

final class ContactSelectedContainerView: UIView {

    private static let logger = Logger.log(ContactSelectedContainerView.self, category: "ContactSelectedContainerView")
    private let disposeBag = DisposeBag()
    private let viewModel: SelectContactListViewModel
    private var selectContacts: [AddressBookContact] = []

    private let emptyCellIdentifier = "EmptyCellIdentifier"
    lazy var selectedCollectionView: UICollectionView = {
        let layout = LeftAlignedCollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = Layout.itemSpacing

        let selectedCollectionView = UICollectionView(frame: .zero,
                                                      collectionViewLayout: layout)
        selectedCollectionView.backgroundColor = UIColor.ud.bgBody
        selectedCollectionView.contentInset = Layout.contentInset
        selectedCollectionView.showsHorizontalScrollIndicator = false
        selectedCollectionView.delegate = self
        selectedCollectionView.dataSource = self
        return selectedCollectionView
    }()

    public init(viewModel: SelectContactListViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        self.registObservables()

        self.addSubview(selectedCollectionView)
        selectedCollectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        selectedCollectionView.register(ContactCollectionCell.self,
                                        forCellWithReuseIdentifier: String(describing: ContactCollectionCell.self))
        selectedCollectionView.register(UICollectionViewCell.self,
                                        forCellWithReuseIdentifier: emptyCellIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func registObservables() {
        self.viewModel.selectedContactsDriver.drive(onNext: { [weak self] selectedContacts in
            self?.selectContacts = selectedContacts
            self?.refreshCollectionView(animated: false)
        }).disposed(by: self.viewModel.disposeBag)
    }

    private func refreshCollectionView(animated: Bool = true) {
        if animated {
            self.selectedCollectionView.performBatchUpdates({
                self.selectedCollectionView.reloadSections(IndexSet(integer: 0))
            }, completion: nil)
        } else {
            self.selectedCollectionView.reloadData()
        }
    }

    public func scrollToItem(at indexPath: IndexPath, animated: Bool) {
        guard indexPath.row < self.selectContacts.count else {
            return
        }
        let scrollPosition: UICollectionView.ScrollPosition
            = (indexPath.row == (self.selectContacts.count - 1)) ? .bottom : .top
        self.selectedCollectionView.scrollToItem(at: IndexPath(row: indexPath.row, section: 0),
                                                 at: scrollPosition,
                                                 animated: animated)
        ContactSelectedContainerView.logger.debug("scrollToItem",
                                                  additionalData: ["row": "\(indexPath.row)",
                                                    "scrollPosition": "\(scrollPosition)"])
    }
}

extension ContactSelectedContainerView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let contact = self.selectContacts[indexPath.row]
        self.viewModel.didSelectedContact(contact: contact)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectContacts.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let name = String(describing: ContactCollectionCell.self)
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: indexPath) as? ContactCollectionCell {
            let model = self.selectContacts[indexPath.row]
            cell.setContent(model.fullName)
            return cell
        } else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: emptyCellIdentifier, for: indexPath)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let contact = self.selectContacts[indexPath.row]
        return CGSize(width: contact.suitableWidth + Layout.itemMarginWidth, height: Layout.itemHeight)
    }
}

extension ContactSelectedContainerView {
    /// get fit height for collection view
    var suitableHeight: CGFloat {
        // swiftlint:disable identifier_name
        if self.selectContacts.isEmpty {
            return 0
        }
        let layoutSize = selectedCollectionView.collectionViewLayout.collectionViewContentSize
        let contentHeight = layoutSize.height
            + Layout.contentInset.top
            + Layout.contentInset.bottom
        if contentHeight == 0 {
            return contentHeight
        }
        // swiftlint:disable identifier_name
        let _suitableHeight = (contentHeight > Layout.selectedMaxHeight) ? Layout.selectedMaxHeight : contentHeight
        ContactSelectedContainerView.logger.debug("suitableHeight:",
                                                  additionalData: ["layoutSize": "\(layoutSize)",
                                                    "contentHeight": "\(contentHeight)",
                                                    "_suitableHeight": "\(_suitableHeight)"])
        return _suitableHeight
        // swiftlint:enable identifier_name
    }
}

extension ContactSelectedContainerView {
    enum Layout {
        static let contentInset: UIEdgeInsets = UIEdgeInsets(top: 12.0, left: 16.0, bottom: 12.0, right: 16.0)
        static let itemSpacing: CGFloat = 12.0
        static let itemHeight: CGFloat = 28.0
        static let itemMarginWidth: CGFloat = 24.0
        static let itemMaxWidth: CGFloat = 147.0
        static let selectedMaxHeight: CGFloat = 132.0
    }
}

extension AddressBookContact {
    var suitableWidth: CGFloat {
        let contentWidth = self.fullName
        .boundingRect(with: CGSize(width: 0, height: 0),
                      options: [.usesLineFragmentOrigin],
                      attributes: [NSAttributedString.Key.font: ContactCollectionCell.nameFont],
                      context: nil)
        .size.width
        return (contentWidth > ContactSelectedContainerView.Layout.itemMaxWidth)
            ? ContactSelectedContainerView.Layout.itemMaxWidth
            : contentWidth
    }
}
