//
//  SegmentPickerTable.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/8/18.
//

import Foundation

struct SegPickerItem {
    let content: String
    var isSelected: Bool
}

typealias SegTableDidSelect = (_ segIndex: Int, _ index: Int) -> Void

class SegTableView: UITableView {

    private(set) var data: [SegPickerItem]
    private let didSelect: SegTableDidSelect
    private let reusableIdentifier: String
    private var lastSelectedIndex: Int? = 0
    private let needSelectIndicator: Bool
    let segIndex: Int

    init(segIndex: Int,
         data: [SegPickerItem],
         didSelect: @escaping SegTableDidSelect,
         reusableIdentifier: String,
         needSelectIndicator: Bool) {
        self.segIndex = segIndex
        self.data = data
        self.didSelect = didSelect
        self.reusableIdentifier = reusableIdentifier
        self.needSelectIndicator = needSelectIndicator
        super.init(frame: .zero, style: .plain)
        super.dataSource = self
        super.delegate = self
        separatorStyle = .none
        estimatedRowHeight = 50
        rowHeight = UITableView.automaticDimension
        register(PickerTableViewCell.self, forCellReuseIdentifier: reusableIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateData(_ data: [SegPickerItem]) {
        lastSelectedIndex = nil
        SuiteLoginUtil.runOnMain {
            self.data = data
            self.reloadData()
        }
    }
}

extension SegTableView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: reusableIdentifier,
            for: indexPath) as? PickerTableViewCell {
            let item = data[indexPath.row]
            cell.updateText(item.content)
            if needSelectIndicator {
                cell.rightImage.isHidden = !item.isSelected
                cell.contentLabel.textColor = item.isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
            }
            return cell
        } else {
            return UITableViewCell()
        }
    }
}

extension SegTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.didSelect(segIndex, indexPath.row)
        if needSelectIndicator {
            data[indexPath.row].isSelected = true
            if let selectIndex = lastSelectedIndex {
                data[selectIndex].isSelected = false
                tableView.reloadRows(at: [indexPath, IndexPath(row: selectIndex, section: 0)], with: .automatic)
            } else {
                tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            lastSelectedIndex = indexPath.row
        }
    }
}

class PickerTableViewCell: UITableViewCell {
    let contentLabel: UILabel = UILabel()
    let rightImage: UIImageView = UIImageView(image: Resource.V3.blue_check.ud.withTintColor(UIColor.ud.primaryContentDefault))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentLabel.font = UIFont.systemFont(ofSize: 16.0)
        contentLabel.numberOfLines = 0
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { (make) in
            make.leading.top.bottom.equalToSuperview().inset(CL.itemSpace)
        }

        rightImage.contentMode = .scaleAspectFit
        rightImage.isHidden = true
        contentView.addSubview(rightImage)
        rightImage.snp.makeConstraints { (make) in
            make.leading.equalTo(contentLabel.snp.trailing).offset(40)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 18, height: 18))
            make.trailing.equalToSuperview().inset(CL.itemSpace)
        }

        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault //lk.N300
        addSubview(line)
        line.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(CL.itemSpace)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(1.0)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateText(_ text: String) {
        contentLabel.attributedText = NSAttributedString.tip(str: text, color: UIColor.ud.textTitle, font: .systemFont(ofSize: 16.0), aligment: .left)
    }
}
