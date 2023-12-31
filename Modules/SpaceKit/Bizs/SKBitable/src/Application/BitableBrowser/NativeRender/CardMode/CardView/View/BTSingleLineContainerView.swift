//
//  BTSingleLineContainerView.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/1.
//

import Foundation

protocol BTSingleContainerItemProtocol: UIView {
    func itemWidth() -> CGFloat
}

protocol BTSingleLineContainerViewDataSource: AnyObject {
    // 获取总共多少个
    func numberOfItem() -> Int
    /// 获取Item
    func itemView(for index: Int) -> BTSingleContainerItemProtocol
    /// 获取+N标签
    func countView(for remain: Int) -> BTSingleContainerItemProtocol
}

public class BTSingleLineContainerView: UIView {
    
    struct Config {
        let itemSpacing: CGFloat
        let itemHeight: CGFloat
    }
    
    private let stackView = UIStackView()
    private let config: Config
    weak var dataSource: BTSingleLineContainerViewDataSource? = nil
    
    required init(with config: Config) {
        self.config = config
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = config.itemSpacing
    }
    
    public func layout(with containerWidth: CGFloat) {
        guard let dataSource = dataSource, dataSource.numberOfItem() > 0, containerWidth > 0 else { return }
        stackView.removeAllArrangedSubviews()
        let totalCount = dataSource.numberOfItem()
        if totalCount == 1 {
            // 不需要显示+N
            let item = dataSource.itemView(for: 0)
            let width = item.itemWidth()
            stackView.addArrangedSubview(item)
            item.snp.makeConstraints { make in
                make.height.equalTo(config.itemHeight)
                make.width.equalTo(min(width, containerWidth))
            }
        } else {
            var totalWidth: CGFloat = 0
            var remainCount = totalCount - 1
            for index in (0...totalCount - 1) {
                let currentItem = dataSource.itemView(for: index)
                let itemWidth = currentItem.itemWidth()
                if index == 0 {
                    let countItem = dataSource.countView(for: remainCount)
                    let countWidth = countItem.itemWidth()
                    let fitWidth = min(containerWidth - countWidth - config.itemSpacing, itemWidth)
                    stackView.addArrangedSubview(currentItem)
                    currentItem.snp.makeConstraints { make in
                        make.height.equalTo(config.itemHeight)
                        make.width.equalTo(fitWidth)
                    }
                    if itemWidth + countWidth + config.itemSpacing >= containerWidth {
                        stackView.addArrangedSubview(countItem)
                        countItem.snp.makeConstraints { make in
                            make.height.equalTo(config.itemHeight)
                            make.width.equalTo(countWidth)
                        }
                        break
                    }
                    totalWidth += fitWidth
                } else {
                    let countItem = dataSource.countView(for: remainCount)
                    let countWidth = countItem.itemWidth()
                    let willFitWidth = totalWidth + config.itemSpacing + itemWidth + config.itemSpacing + countWidth
                    if willFitWidth < containerWidth {
                        stackView.addArrangedSubview(currentItem)
                        currentItem.snp.makeConstraints { make in
                            make.height.equalTo(config.itemHeight)
                            make.width.equalTo(itemWidth)
                        }
                        totalWidth += config.itemSpacing + itemWidth
                        remainCount -= 1
                    } else {
                        stackView.addArrangedSubview(countItem)
                        countItem.snp.makeConstraints { make in
                            make.height.equalTo(config.itemHeight)
                            make.width.equalTo(countWidth)
                        }
                        break
                    }
                }
            }
        }
    }
    
}
