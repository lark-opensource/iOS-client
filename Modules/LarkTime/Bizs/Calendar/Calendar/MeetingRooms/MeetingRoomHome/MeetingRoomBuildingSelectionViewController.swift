//
//  MeetingRoomBuildingSelectionViewController.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/5/11.
//

import UniverseDesignIcon
import UIKit
import RxCocoa
import LarkUIKit
import RxSwift
import CTFoundation
import LarkTag
import UniverseDesignFont

private typealias ViewModel = MeetingRoomHomeViewModel

final class MeetingRoomBuildingSelectionViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {

    static var allFloorsStr: String {
        BundleI18n.Calendar.Calendar_Common_All
    }

    enum State {
        case building, floor
    }

    var state = State.building {
        didSet {
            headerView.state = state
            tableView.reloadData()
            let isFirstLevel = state == .building
            headerView.closeButton.isHidden = !isFirstLevel
            headerView.confirmButton.isHidden = isFirstLevel
        }
    }

    private var searchTextRelay = BehaviorRelay<String>(value: "")

    private lazy var emptyPlaceHolderBuilding: Rust.Building = {
        var building = Rust.Building()
        building.name = BundleI18n.Calendar.Calendar_Search_NoBuildingsFound
        return building
    }()

    var buildings = [Rust.Building]()

    private var buildingsWithFilter: [Rust.Building] {
        let text = searchTextRelay.value

        var filtered = text.isEmpty ? buildings : buildings.filter { $0.pinyinName.lowercased().contains(text.lowercased()) || $0.name.lowercased().contains(text.lowercased()) }
        if let selected = selectedBuilding,
           let selectedIndex = filtered.firstIndex(where: { $0.id == selected.id }) {
            filtered.remove(at: selectedIndex)
            filtered.insert(selected, at: 0)
        }

        if !text.isEmpty && filtered.isEmpty {
            return [emptyPlaceHolderBuilding]
        }

        return filtered
    }

    var displayingBuilding: Rust.Building? {
        willSet {
            if newValue == displayingBuilding {
                // do nothing
                return
            } else if newValue != nil {
                if newValue == selectedBuilding {
                    var floors = ([Self.allFloorsStr] + newValue!.floors).map { ($0, selectedFloors.contains($0)) }
                    if !floors.filter({ $0.0 != Self.allFloorsStr }).map(\.1).contains(true) {
                        floors[0].1 = true
                    }
                    if selectedFloors.contains(Self.allFloorsStr) {
                        floors = ([Self.allFloorsStr] + newValue!.floors).map { ($0, false) }
                        floors[0].1 = true
                    }
                    displayingFloors = floors
                } else {
                    displayingFloors = [(Self.allFloorsStr, true)] + newValue!.floors.map { ($0, false) }
                }
            }
        }
    }
    private var displayingFloors = [(String, Bool)]()

    var selectedBuilding: Rust.Building?
    var selectedFloors = [String]()

    var didSelectBuildingAndFloors: ((Rust.Building?, [String]) -> Void)?

    private let bag = DisposeBag()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 48
        tableView.separatorStyle = .none
        tableView.tintColor = .ud.primaryContentDefault
        return tableView
    }()

    private lazy var headerView: HeaderView = {
        let view = HeaderView()
        view.backgroundColor = UIColor.ud.bgBody

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)

        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
        }
        headerView.state = .building

        view.addSubview(tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.keyboardDismissMode = .onDrag
        tableView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        if let gesture = popupViewController?.interactivePopupGestureRecognizer {
            tableView.panGestureRecognizer.require(toFail: gesture)
        }

        let tap = UITapGestureRecognizer()
        headerView.backIcon.addGestureRecognizer(tap)
        tap.rx.event.asDriver().drive(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.state = .building
        })
        .disposed(by: bag)

        headerView.closeButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag)

        headerView.confirmButton.rx.tap.asDriver()
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.selectedFloors = self.displayingFloors.filter(\.1).map(\.0)
                self.selectedBuilding = self.displayingBuilding
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag)

        headerView.searchTextField.rx.text.orEmpty.asDriver()
            .drive(searchTextRelay)
            .disposed(by: bag)

        searchTextRelay.subscribeForUI(onNext: { [weak self] _ in
            self?.tableView.reloadData()
        })
        .disposed(by: bag)

        isNavigationBarHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        didSelectBuildingAndFloors?(selectedBuilding, selectedFloors.isEmpty ? (selectedBuilding?.floors ?? []) : selectedFloors)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state == .building ? buildingsWithFilter.count : displayingFloors.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bottomSeparatorTag = 10_001

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.selectionStyle = .none

        var sepLine = cell.viewWithTag(bottomSeparatorTag)
        if sepLine == nil {
            sepLine = cell.addBottomSepratorLine()
            sepLine?.tag = bottomSeparatorTag
        }

        if state == .building {
            guard let building = buildingsWithFilter[safeIndex: indexPath.row] else {
                return UITableViewCell()
            }
            cell.textLabel?.text = building.name
            cell.textLabel?.font = UDFont.systemFont(ofSize: 17)
            let selected = building.id == selectedBuilding?.id
            cell.imageView?.image = UDIcon.getIconByKeyNoLimitSize(.buildingOutlined).renderColor(with: .n3)
            cell.textLabel?.textColor = selected ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
            cell.accessoryType = .disclosureIndicator
            if building.name == emptyPlaceHolderBuilding.name {
                cell.imageView?.image = nil
                cell.accessoryType = .none
            }
            let imageSize = CGSize(width: 16, height: 16)
            UIGraphicsBeginImageContextWithOptions(imageSize, false, UIScreen.main.scale)
            let imageRect = CGRect(origin: .zero, size: imageSize)
            cell.imageView?.image?.draw(in: imageRect)
            cell.imageView?.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            sepLine?.isHidden = true
        } else {
            guard let floor = displayingFloors[safeIndex: indexPath.row] else {
                return UITableViewCell()
            }
            cell.imageView?.image = nil
            cell.textLabel?.text = floor.0
            cell.textLabel?.textColor = UIColor.ud.textTitle
            cell.accessoryType = floor.1 ? .checkmark : .none
            sepLine?.isHidden = false
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        if state == .building {
            let selectedBuilding = buildingsWithFilter[indexPath.row]
            guard selectedBuilding.name != emptyPlaceHolderBuilding.name else { return }
            displayingBuilding = selectedBuilding
            state = .floor
        } else if state == .floor {
            if indexPath.row == 0 {
                // 全选
                if displayingFloors[0].1 { return }
                displayingFloors = displayingFloors.map { ($0.0, false) }
                displayingFloors[0].1 = true
                tableView.reloadData()
            } else {
                var floor = displayingFloors[indexPath.row]
                floor.1.toggle()
                displayingFloors[indexPath.row] = floor

                // 如果有任意一个楼层被选中 取消全选
                // 如果没有任何楼层被选中 勾选全选
                displayingFloors[0].1 = !displayingFloors.filter { $0.0 != Self.allFloorsStr }.map(\.1).contains(true)

                tableView.reloadRows(at: [indexPath], with: .none)
                tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            }
        }
    }
}

extension MeetingRoomBuildingSelectionViewController: PopupViewControllerItem {
    var hoverPopupOffsets: [PopupOffset] {
        [.full]
    }

    var preferredPopupOffset: PopupOffset {
        .full
    }

    var naviBarStyle: Popup.NaviBarStyle {
        .none
    }

    func shouldBeginPopupInteractingInCompact(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    func shouldBeginPopupInteractingInRegular(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let popupViewController = popupViewController,
            interactivePopupGestureRecognizer == popupViewController.interactivePopupGestureRecognizer,
            let panGesture = interactivePopupGestureRecognizer as? UIPanGestureRecognizer else {
            return true
        }
        let velocity = panGesture.velocity(in: panGesture.view)
        let point = panGesture.location(in: self.view)

        // 手势开始时不在tableview中
        if !tableView.frame.contains(point) {
            return true
        }

        // 左滑 or 右滑
        if abs(velocity.x) > abs(velocity.y) {
            return false
        }

        // 上滑
        if velocity.y < 0 {
            return false
        }
        // 下滑
        if velocity.y > 0 && tableView.contentOffset.y > 0.1 {
            return false
        }
        return true
    }

    func popupBackgroundDidClick() {
        popupViewController?.dismiss(animated: true, completion: nil)
    }
}

extension MeetingRoomBuildingSelectionViewController {
    fileprivate final class HeaderView: UIView {

        private var bottomConstraint: NSLayoutConstraint?

        var state = State.building {
            didSet {
                let building = state == .building
                backIcon.isHidden = building
                bottomConstraint?.isActive = !building
                titleLabel.text = (building ? BundleI18n.Calendar.Calendar_Edit_SelectBuildingTitle : BundleI18n.Calendar.Calendar_Edit_SelectFloorTitle)
            }
        }

        lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.text = BundleI18n.Calendar.Calendar_Edit_SelectBuildingAndFloor
            label.font = UIFont.ud.title3(.fixed)
            label.textColor = UIColor.ud.textTitle
            label.numberOfLines = 1
            return label
        }()

        lazy var backIcon: UIImageView = {
            let imageView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.leftOutlined).renderColor(with: .n1))
            imageView.isHidden = true
            imageView.isUserInteractionEnabled = true
            return imageView
        }()

        lazy var closeButton: UIButton = {
            let button = UIButton(type: .custom)
            button.setImage(UDIcon.getIconByKeyNoLimitSize(.closeSmallOutlined).ud.resized(to: CGSize(width: 20, height: 20)).renderColor(with: .n1), for: .normal)
            return button
        }()

        lazy var confirmButton: UIButton = {
            let confirmButton = UIButton(type: .custom)
            confirmButton.setTitle(I18n.Calendar_Common_Confirm, for: .normal)
            confirmButton.titleLabel?.font = UIFont.ud.headline(.fixed)
            confirmButton.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
            confirmButton.setTitleColor(UIColor.ud.primaryContentLoading, for: .disabled)
            confirmButton.isHidden = true
            return confirmButton
        }()

        lazy var searchTextField: UITextField = {
            let textField = UITextField(frame: .zero)
            textField.borderStyle = .none
            textField.textColor = UIColor.ud.titleColor
            textField.backgroundColor = UIColor.ud.bgFiller
            textField.placeholder = BundleI18n.Calendar.Calendar_Search_SearchBuildings
            textField.layer.cornerRadius = 4
            textField.layer.masksToBounds = true
            textField.clearButtonMode = .always
            textField.font = UIFont.body2

            let wrapperView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: 24))
            let iconView = UIImageView(image: UDIcon.getIconByKeyNoLimitSize(.searchOutlined).renderColor(with: .n3))
            iconView.contentMode = .scaleAspectFit
            iconView.frame = CGRect(x: 8, y: 4, width: 16, height: 16)
            wrapperView.addSubview(iconView)
            textField.leftView = wrapperView
            textField.leftViewMode = .always

            return textField
        }()

        override init(frame: CGRect) {
            super.init(frame: frame)

            addSubview(titleLabel)
            titleLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(16)
                make.centerX.equalToSuperview().inset(16)
            }
            bottomConstraint = titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)

            addSubview(searchTextField)
            searchTextField.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(16)
                make.top.equalTo(titleLabel.snp.bottom).offset(24)
                make.height.equalTo(32)
                make.bottom.equalToSuperview().inset(12).priority(.low)
            }

            addSubview(backIcon)
            backIcon.snp.makeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.leading.equalToSuperview().inset(16)
                make.size.equalTo(CGSize(width: 20, height: 20))
            }

            addSubview(closeButton)
            closeButton.snp.makeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.leading.equalToSuperview().inset(16)
                make.size.equalTo(CGSize(width: 20, height: 20))
            }

            addSubview(confirmButton)
            confirmButton.snp.makeConstraints { make in
                make.centerY.equalTo(titleLabel)
                make.trailing.equalToSuperview().inset(16)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
