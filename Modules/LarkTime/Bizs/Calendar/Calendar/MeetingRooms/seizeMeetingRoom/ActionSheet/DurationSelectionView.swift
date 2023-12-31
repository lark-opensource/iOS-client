//
//  DurationSelectionView.swift
//  AudioSessionScenario
//
//  Created by harry zou on 2019/4/18.
//

import UIKit
import RxSwift
import RxCocoa
import LarkTimeFormatUtils

final class DurationSelectionView: UIView {
    private var model: DurationSelectionModel
    private let defaultDurition: Int
    private(set) var selectedTime: Int = -1
    private let is12HourStyle: BehaviorRelay<Bool>
    private let disposeBag = DisposeBag()

    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 52
        tableView.separatorStyle = .none
        tableView.register(DurationSelctionCell.self, forCellReuseIdentifier: "DurationSelctionCell")
        return tableView
    }()

    init(model: DurationSelectionModel,
         defaultDurition: Int,
         is12HourStyle: BehaviorRelay<Bool>) {
        self.model = model
        self.defaultDurition = defaultDurition
        self.is12HourStyle = is12HourStyle
        super.init(frame: .zero)
        addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.bottom.left.right.equalToSuperview()
            let height: CGFloat = CGFloat(52 * self.model.reloadEndTimes().count)
            make.height.equalTo(height).priority(751)
        }
        self.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        tableView.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        setDefaultDuration()
        is12HourStyle.asDriver().skip(1).drive(onNext: { [weak self] (_) in
            self?.tableView.reloadData()
        }).disposed(by: disposeBag)
    }

    func update(model: DurationSelectionModel) {
        self.model = model
        let selectedPath = tableView.indexPathForSelectedRow
        tableView.reloadData()
        if let selectedPath = selectedPath, selectedPath.row > self.model.endTimes.count - 1 {
            tableView.selectRow(at: IndexPath(row: model.endTimes.count - 1, section: 0), animated: false, scrollPosition: .none)
            selectedTime = Int(model.endTimes[model.endTimes.count - 1])
            return
        }
        if let row = selectedPath?.row, let endTime = model.endTimes[safeIndex: row] {
            selectedTime = Int(endTime)
        }

        tableView.selectRow(at: selectedPath, animated: false, scrollPosition: .none)
    }

    func setDefaultDuration() {
        assert(!model.endTimes.isEmpty)
        // 初始选择 duration 最接近 defaultDuration 的选项
        if let min = model.endTimes.min(by: { abs(model.getDurition(endTime: $0) - defaultDurition) < abs(model.getDurition(endTime: $1) - defaultDurition) }) {
            let index = model.endTimes.firstIndex(of: min)!
            tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
            selectedTime = Int(min)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension DurationSelectionView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.model.endTimes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let endTime = self.model.endTimes[safeIndex: indexPath.row],
        let cell = tableView.dequeueReusableCell(withIdentifier: "DurationSelctionCell", for: indexPath) as? DurationSelctionCell
            else { return UITableViewCell() }
        let customOptions = Options(
            is12HourStyle: is12HourStyle.value,
            timePrecisionType: .minute
        )
        let date = Date(timeIntervalSince1970: endTime)
        let timeString = BundleI18n.Calendar.Calendar_Takeover_Next(NextStartTime: 
            TimeFormatUtils.formatTime(from: date, with: customOptions)
            )
            + " ("
            + BundleI18n.Calendar.Calendar_Plural_Duration(number: self.model.getDurition(endTime: endTime))
            + ")"
        cell.update(timeString: timeString)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let endTime = self.model.endTimes[safeIndex: indexPath.row] else {
            return
        }
        selectedTime = Int(endTime)
    }
}
