//
//  DetailDependentDialogCustomView.swift
//  Todo
//
//  Created by wangwanxin on 2023/7/25.
//

import Foundation
import UniverseDesignFont

struct DetailDependentDialogCustomViewData {
    var headerText: String?
    var items: [String]?
}

final class DetailDependentDialogCustomView: UIView {

    var viewData: DetailDependentDialogCustomViewData? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            header.text = viewData.headerText
            viewData.items?.enumerated().forEach { (index, value) in
                if index < Config.maxItem {
                    items[index].isHidden = false
                    if index == Config.maxItem - 1 {
                        items[index].text = "• …"
                    } else {
                        items[index].text = "• \(value)"
                    }
                } else {
                    return
                }
            }

        }
    }

    private lazy var header: UILabel = getLabel()

    private lazy var list: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        return stack
    }()

    // 最多展示6个
    private lazy var items: [UILabel] = {
        var items = [UILabel]()
        for _ in 0..<Config.maxItem {
            let label = getLabel()
            label.isHidden = true
            items.append(getLabel())
        }
        return items
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(header)
        header.numberOfLines = 0
        addSubview(list)
        header.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }
        for item in items {
            list.addArrangedSubview(item)
        }
        list.snp.makeConstraints { make in
            make.top.equalTo(header.snp.bottom).offset(12)
            make.left.right.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }



    private func getLabel() -> UILabel {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        return label
    }


    struct Config {
        static let maxItem: Int = 6
    }

}
