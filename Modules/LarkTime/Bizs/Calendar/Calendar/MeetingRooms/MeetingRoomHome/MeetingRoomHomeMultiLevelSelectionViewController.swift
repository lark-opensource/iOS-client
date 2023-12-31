//
//  MeetingRoomHomeMultiLevelSelectionViewController.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/9/1.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkContainer

/// 用于会议室视图 包装了 MeetingRoomMultiLevelSelectionViewController 的外壳
final class MeetingRoomHomeMultiLevelSelectionViewController: UIViewController, UIGestureRecognizerDelegate, UserResolverWrapper {
    private lazy var headerView: HeaderView = {
        let header = HeaderView()
        header.state = .level
        return header
    }()

    var confirmButton: UIButton {
        headerView.multiSelectionConfirmButton
    }

    private let bag = DisposeBag()
    private var injectedRootLevel: MLLevel?
    private var selectedLevelIds: [String]?
    weak var multiSelectionVC: MeetingRoomMultiLevelSelectionViewController?

    let userResolver: UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tap = UITapGestureRecognizer()
        view.addGestureRecognizer(tap)
        tap.delegate = self
        _ = tap.rx.event.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.dismiss(animated: false)
            })

        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.snp.bottom)
            make.height.equalTo(64)
        }

        let config = MeetingRoomMultiLevelSelectionViewController.Config(showLevelsOnly: true,
                                                                         selectedLevelIds: self.selectedLevelIds,
                                                                         injectedRootLevel: self.injectedRootLevel,
                                                                         source: .meetingHome)
        let multiSelectionVC = MeetingRoomMultiLevelSelectionViewController(config: config, userResolver: self.userResolver)
        addChild(multiSelectionVC)
        view.addSubview(multiSelectionVC.view)
        multiSelectionVC.view.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).priority(.low)
            make.leading.trailing.bottom.equalToSuperview()
        }
        multiSelectionVC.didMove(toParent: self)
        self.multiSelectionVC = multiSelectionVC

        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.layoutIfNeeded()

        view.backgroundColor = .clear
        headerView.snp.remakeConstraints { make in
            make.top.equalToSuperview().inset(88)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(64)
        }

        UIView.animate(withDuration: 0.25) {
            self.view.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.5)
            self.view.layoutIfNeeded()
        }
    }

    func bind() {
        headerView.closeButton.rx.tap
            .amb(headerView.multiSelectionConfirmButton.rx.tap)
            .asDriver(onErrorJustReturn: ())
            .drive(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: bag)

        multiSelectionVC?.rx.selectedLevelIds
            .startWith([])
            .map(\.isEmpty).map(!)
            .observeOn(MainScheduler.instance)
            .bind(to: headerView.multiSelectionConfirmButton.rx.isEnabled)
            .disposed(by: bag)

        // uncomment to show selected count
//        multiSelectionVC?.rx.selectedMeetingRooms
//            .map { BundleI18n.Calendar.Calendar_Common_Confirm + ($0.isEmpty ? "" : "(\($0.count))") }
//            .observeOn(MainScheduler.instance)
//            .bind(to: headerView.multiSelectionConfirmButton.rx.title(for: .normal))
//            .disposed(by: bag)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        headerView.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.snp.bottom)
            make.height.equalTo(64)
        }
        UIView.animate(withDuration: 0.25) {
            self.view.backgroundColor = .clear
            self.view.layoutIfNeeded()
        } completion: { _ in
            super.dismiss(animated: false, completion: completion)
        }
    }
}

extension MeetingRoomHomeMultiLevelSelectionViewController {
    convenience init(rootLevel: MLLevel?, selectedLevelIds: [String] = [], userResolver: UserResolver) {
        self.init(userResolver: userResolver)
        injectedRootLevel = rootLevel
        self.selectedLevelIds = selectedLevelIds
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MeetingRoomHomeMultiLevelSelectionViewController {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: view)
        return view.hitTest(location, with: nil) == view
    }
}

extension MeetingRoomHomeMultiLevelSelectionViewController {
    fileprivate final class HeaderView: UIView {
        enum State {
            case building, level
        }

        var state: State {
            didSet {
                switch state {
                case .building:
                    titleLabel.text = BundleI18n.Calendar.Calendar_Rooms_SelectRoomsLevel
                case .level:
                    titleLabel.text = BundleI18n.Calendar.Calendar_G_SelectLayerPlaceholder
                }
            }
        }

        fileprivate lazy var closeButton: UIButton = {
            let button = UIButton()
            button.setImage(UIImage.cd.image(named: "chat_float_close").ud.withTintColor(UIColor.ud.N900), for: .normal)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            return button
        }()

        fileprivate lazy var multiSelectionConfirmButton: UIButton = {
            let button = UIButton(type: .custom)
            button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
            button.setTitle(BundleI18n.Calendar.Calendar_Common_Confirm, for: .normal)
            button.titleLabel?.font = UIFont.ud.body0(.fixed)
            button.setContentCompressionResistancePriority(.required, for: .horizontal)
            return button
        }()

        private(set) lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = UIFont.ud.title3(.fixed)
            label.text = BundleI18n.Calendar.Calendar_Edit_SelectBuildingTitle
            label.textColor = UIColor.ud.N900
            label.numberOfLines = 1
            return label
        }()

        override init(frame: CGRect) {
            state = .level
            super.init(frame: frame)

            layoutMargins = UIEdgeInsets(horizontal: 16, vertical: 0)

            backgroundColor = UIColor.ud.N00
            layer.cornerRadius = 5
            layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

            addSubview(closeButton)
            addSubview(titleLabel)
            addSubview(multiSelectionConfirmButton)

            closeButton.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalTo(snp.leadingMargin)
            }

            titleLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.leading.lessThanOrEqualTo(closeButton.snp.trailing)
                make.trailing.lessThanOrEqualTo(multiSelectionConfirmButton.snp.leading)
            }

            multiSelectionConfirmButton.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalTo(snp.trailingMargin)
            }

            addBottomSepratorLine()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
