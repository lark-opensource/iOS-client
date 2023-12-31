//
//  MeetDialViewController.swift
//  ByteView
//
//  Created by wangpeiran on 2021/7/14.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit
import UIKit
import RxSwift
import Action
import RxCocoa
import ByteViewCommon
import UniverseDesignIcon

final class MeetDialViewController: VMViewController<MeetDialViewModel>, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    private lazy var backButton: UIButton = {
        let button = EnlargeTouchButton(padding: 10)
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)), for: .normal)
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: .ud.iconN3, size: CGSize(width: 24, height: 24)), for: .highlighted)
        button.addInteraction(type: .highlight, shape: .roundedRect(CGSize(width: 44, height: 36), nil))
        return button
    }()

    lazy var titleLable: UILabel = {
        let label = UILabel()
        label.text = viewModel.title
        label.font = UIFont.systemFont(ofSize: 17, weight: Display.pad ? .medium : .regular)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var inputLable: UILabel = {
        let label = UILabel()
        label.text = viewModel.defaultValue
        label.font = UIFont.systemFont(ofSize: 30, weight: .semibold)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.lineBreakMode = .byTruncatingHead
        label.numberOfLines = 1
        return label
    }()

    private lazy var itemLayout: UICollectionViewLayout = {
        let itemLayout = UICollectionViewFlowLayout.init()
        itemLayout.itemSize = CGSize(width: 72, height: 72)
        itemLayout.scrollDirection = .vertical
        itemLayout.minimumInteritemSpacing = 28
        itemLayout.minimumLineSpacing = 32
        return itemLayout
    }()

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var collectionView: UICollectionView = {
        UICollectionView.init(frame: .zero, collectionViewLayout: itemLayout)
    }()

    var tapNumberBlock: ((String) -> Void)?

    let isIPadLayout: BehaviorRelay<Bool> = BehaviorRelay<Bool>(value: false)

    var disposeBag: DisposeBag = DisposeBag()

    override func setupViews() {
        view.backgroundColor = UIColor.ud.bgBody
        edgesForExtendedLayout = .bottom
        isNavigationBarHidden = true
        view.addSubview(backButton)
        view.addSubview(titleLable)
        containerView.addSubview(collectionView)
        containerView.addSubview(inputLable)
        view.addSubview(containerView)

        isIPadLayout.distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.updateDynamicModalSize(CGSize(width: 375, height: 620))
            })
            .disposed(by: rx.disposeBag)

        backButton.snp.makeConstraints { (maker) in
            maker.size.equalTo(24)
            maker.left.equalToSuperview().inset(16)
            maker.top.equalTo(view.safeAreaLayoutGuide).offset(Display.pad ? 18 : 10)
        }

        titleLable.snp.makeConstraints { (maker) in
            maker.height.equalTo(24)
            maker.left.equalTo(self.backButton.snp.right).offset(12)
            maker.right.equalToSuperview().offset(-52)
            maker.centerY.equalTo(backButton)
        }

        containerView.snp.makeConstraints { (maker) in
            maker.left.right.bottom.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
            maker.top.equalTo(backButton.snp.bottom).offset(10)
        }

        inputLable.snp.makeConstraints { (maker) in
            maker.height.equalTo(30)
            maker.left.equalToSuperview().offset(51)
            maker.right.equalToSuperview().offset(-51)
            maker.top.equalToSuperview().offset(46)
        }

        if Display.pad {
            collectionView.snp.makeConstraints { (maker) in
                maker.size.equalTo(CGSize(width: 272, height: 384))
                maker.centerX.equalToSuperview()
                maker.top.equalTo(inputLable.snp.bottom).offset(56)
            }
        } else {
            collectionView.snp.makeConstraints { (maker) in
                maker.size.equalTo(CGSize(width: 272, height: 384))
                maker.centerX.equalToSuperview()
                maker.centerY.equalToSuperview().inset(6)
            }
        }
        setupCollectionView()
    }

    override func bindViewModel() {
        backButton.rx.action = CocoaAction(workFactory: { [weak self] _ in
            self?.presentingViewController?.dismiss(animated: true, completion: nil)
            return .empty()
        })

        viewModel.leaveRelay
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLeave in
                if isLeave {
                    self?.presentingViewController?.dismiss(animated: true, completion: nil)
                }
            })
            .disposed(by: disposeBag)

        self.tapNumberBlock = {[weak self] (number: String) in
            let str = (self?.inputLable.text ?? "").appending(number)
            self?.inputLable.text = str
            self?.viewModel.selectedAction(chat: number, totalTitle: str)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDynamicModalSize(CGSize(width: 375, height: 620))
    }

    func setupCollectionView() {
        collectionView.backgroundColor = UIColor.clear
        collectionView.delegate = self
        collectionView.dataSource = self

        collectionView.register(MeetDialCell.self, forCellWithReuseIdentifier: "meetDialCell")
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "meetDialCell",
                                                         for: indexPath) as? MeetDialCell {
            cell.bindData(model: viewModel.dataSource[indexPath.row])
            cell.tapBlock = tapNumberBlock
            return cell
        }
        return UICollectionViewCell(frame: .zero)
    }
}

extension MeetDialViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        isIPadLayout.accept(isRegular)
    }
}
