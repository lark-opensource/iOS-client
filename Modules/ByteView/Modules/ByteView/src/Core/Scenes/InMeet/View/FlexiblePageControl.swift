//
//  FlexiblePageControl.swift
//  ByteView
//
//  Created by Prontera on 2019/10/13.
//

import UIKit

protocol FlexiblePageControlDelegate: AnyObject {
    func didChangeCurrentPage(to page: Int)
}

final class FlexiblePageControl: UIView {

    // MARK: public
    struct Config: Equatable {

        var displayCount: Int
        var dotSize: CGFloat
        var verticalPadding: CGFloat
        var horizontalPadding: CGFloat
        var smallDotSize: CGFloat
        var mediumDotSize: CGFloat
        var enableMove: Bool
        init(dotSize: CGFloat = 6.0,
             dotSpace: CGFloat,
             mediumDotSize: CGFloat = 4,
             smallDotSize: CGFloat = 2,
             enableMove: Bool = true) {
            self.init(dotSize: dotSize,
                      verticalPadding: dotSpace / 2,
                      horizontalPadding: dotSpace / 2,
                      mediumDotSize: mediumDotSize,
                      smallDotSize: smallDotSize,
                      enableMove: enableMove)
        }

        init(dotSize: CGFloat = 6.0,
             verticalPadding: CGFloat = 2.0,
             horizontalPadding: CGFloat = 2.0,
             mediumDotSize: CGFloat = 4,
             smallDotSize: CGFloat = 2,
             enableMove: Bool = true) {
            self.displayCount = 5
            self.dotSize = dotSize
            self.verticalPadding = verticalPadding
            self.horizontalPadding = horizontalPadding
            self.mediumDotSize = mediumDotSize
            self.smallDotSize = smallDotSize
            self.enableMove = enableMove
        }
    }

    // default config

    var config = Config() {
        didSet {
            guard config != oldValue else {
                return
            }
            updateConfig()
        }
    }

    func setCurrentPage(at currentPage: Int, animated: Bool = false) {
        guard currentPage < numberOfPages, currentPage >= 0, currentPage != self.currentPage else { return }
        scrollView.layer.removeAllAnimations()
        updateDot(at: currentPage, animated: animated)
        self.currentPage = currentPage
        delegate?.didChangeCurrentPage(to: currentPage)
    }

    private(set) var currentPage: Int = 0

    var numberOfPages: Int = 0 {
        didSet {
            scrollView.isHidden = (numberOfPages <= 1 && hidesForSinglePage)
            displayCount = min(config.displayCount, numberOfPages)
            update(currentPage: currentPage, config: config)
        }
    }

    var pageIndicatorTintColor: UIColor = UIColor.ud.iconDisabled {
        didSet {
            updateDotColor(currentPage: currentPage)
        }
    }

    var currentPageIndicatorTintColor: UIColor = UIColor.ud.primaryContentDefault {
        didSet {
            updateDotColor(currentPage: currentPage)
        }
    }

    var animateDuration: TimeInterval = 0.3

    var hidesForSinglePage: Bool = false {
        didSet {
            scrollView.isHidden = (numberOfPages <= 1 && hidesForSinglePage)
        }
    }

    weak var delegate: FlexiblePageControlDelegate?

    init(config: Config) {
        super.init(frame: .zero)

        self.config = config
        setup()
        updateViewSize()
    }

    init() {

        super.init(frame: .zero)

        setup()
        updateViewSize()
    }

    override init(frame: CGRect) {

        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)

        setup()
        updateViewSize()
    }

    override func layoutSubviews() {

        super.layoutSubviews()

        scrollView.center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: itemWidth * CGFloat(displayCount) + config.horizontalPadding * 2, height: itemHeight)
    }

    func setProgress(contentOffsetX: CGFloat, pageWidth: CGFloat) {

        let currentPage = Int(round(contentOffsetX / pageWidth))
        setCurrentPage(at: currentPage, animated: true)
    }

    func updateViewSize() {
        self.bounds.size = intrinsicContentSize
    }

    private func updateConfig() {
        update(currentPage: currentPage, config: config)
        invalidateIntrinsicContentSize()
    }

    // MARK: private

    private let scrollView = UIScrollView()

    private var itemWidth: CGFloat {
        return config.dotSize + config.horizontalPadding * 2
    }

    private var itemHeight: CGFloat {
        return config.dotSize + config.verticalPadding * 2
    }

    private var items: [ItemView] = []

    private var displayCount: Int = 0 {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    private func setup() {

        backgroundColor = .clear

        scrollView.backgroundColor = .clear
        scrollView.isUserInteractionEnabled = false
        scrollView.showsHorizontalScrollIndicator = false

        addSubview(scrollView)
    }

    private func update(currentPage: Int, config: Config) {

        let itemConfig = ItemView.ItemConfig(dotSize: config.dotSize,
                                             itemWidth: itemWidth,
                                             verticalPadding: config.verticalPadding,
                                             mediumDotSize: config.mediumDotSize,
                                             smallDotSize: config.smallDotSize)
        if currentPage < displayCount {
            items = (-2..<(displayCount + 2))
                .map { ItemView(config: itemConfig, index: $0) }
        } else {
            guard let firstItem = items.first, let lastItem = items.last else { return }
            items = (firstItem.index...lastItem.index)
                .map { ItemView(config: itemConfig, index: $0) }
        }

        scrollView.subviews.forEach { $0.removeFromSuperview() }
        items.forEach { scrollView.addSubview($0) }
        let size: CGSize = CGSize(width: itemWidth * CGFloat(displayCount),
                                  height: itemHeight)

        scrollView.bounds.size = size
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        updateDot(at: currentPage, animated: false)
    }

    private func updateDot(at currentPage: Int, animated: Bool) {

        updateDotColor(currentPage: currentPage)
        if numberOfPages >= displayCount && numberOfPages > config.displayCount {
            updateDotPosition(currentPage: currentPage, animated: animated)
            updateDotSize(currentPage: currentPage, animated: animated)
        }
    }

    private func updateDotColor(currentPage: Int) {

        items.forEach {
            $0.dotColor = ($0.index == currentPage) ?
                currentPageIndicatorTintColor : pageIndicatorTintColor
        }
    }

    private func updateDotPosition(currentPage: Int, animated: Bool) {
        let duration = animated ? animateDuration : 0
        if CGFloat(currentPage) * itemWidth >= CGFloat(numberOfPages + config.displayCount / 2) * itemWidth - scrollView.bounds.width {
            let x = CGFloat(numberOfPages) * itemWidth - scrollView.bounds.width
            moveScrollView(x: x, duration: duration)
        } else if CGFloat(currentPage) * itemWidth <= CGFloat(config.displayCount / 2) * itemWidth {
            let x = 0.0
            moveScrollView(x: x, duration: duration)
        } else {
            let x = CGFloat(currentPage) * itemWidth - CGFloat(config.displayCount / 2) * itemWidth
            moveScrollView(x: x, duration: duration)
        }
    }

    private func updateDotSize(currentPage: Int, animated: Bool) {

        let duration = animated ? animateDuration : 0

        items.forEach { item in
            item.animateDuration = duration
            if item.index == currentPage {
                item.state = .normal
            }
                // outside of left
            else if item.index < 0 {
                item.state = .none
            }
                // outside of right
            else if item.index > numberOfPages - 1 {
                item.state = .none
            }
                // 首尾一小段
            else if (item.index < config.displayCount / 2 && currentPage <= config.displayCount / 2) || (numberOfPages - 1 - item.index < config.displayCount / 2 && (numberOfPages - 1 - currentPage <= config.displayCount / 2)) {
                item.state = .normal
            }

                // first dot from left
            else if item.frame.minX <= scrollView.contentOffset.x {
                item.state = .small
            }
                // first dot from right
            else if item.frame.maxX >= scrollView.contentOffset.x + scrollView.bounds.width {
                item.state = .small
            }
                // second dot from left
            else if item.frame.minX <= scrollView.contentOffset.x + itemWidth {
                item.state = .medium
            }
                // second dot from right
            else if item.frame.maxX >= scrollView.contentOffset.x + scrollView.bounds.width - itemWidth {
                item.state = .medium
            } else {
                item.state = .normal
            }
        }
    }

    private func moveScrollView(x: CGFloat, duration: TimeInterval) {
        guard config.enableMove else { return }
        let direction = behaviorDirection(x: x)
        reusedView(direction: direction)
        UIView.animate(withDuration: duration, animations: { [unowned self] in
            self.scrollView.contentOffset.x = x
        })
    }

    private enum Direction {
        case left
        case right
        case stay
    }

    private func behaviorDirection(x: CGFloat) -> Direction {

        switch x {
        case let x where x > scrollView.contentOffset.x:
            return .right
        case let x where x < scrollView.contentOffset.x:
            return .left
        default:
            return .stay
        }
    }

    private func reusedView(direction: Direction) {

        guard let firstItem = items.first else { return }
        guard let lastItem = items.last else { return }

        switch direction {
        case .left:

            lastItem.index = firstItem.index - 1
            lastItem.frame = CGRect(x: CGFloat(lastItem.index) * itemWidth, y: 0, width: itemWidth, height: itemHeight)
            items.insert(lastItem, at: 0)
            items.removeLast()

        case .right:

            firstItem.index = lastItem.index + 1
            firstItem.frame = CGRect(x: CGFloat(firstItem.index) * itemWidth, y: 0, width: itemWidth, height: itemHeight)
            items.insert(firstItem, at: items.count)
            items.removeFirst()

        case .stay:

            break
        }
    }
}

private class ItemView: UIView {

    struct ItemConfig {
        var dotSize: CGFloat
        var itemWidth: CGFloat
        var verticalPadding: CGFloat
        var mediumDotSize: CGFloat
        var smallDotSize: CGFloat
    }

    enum State {
        case none
        case small
        case medium
        case normal
    }

    var index: Int

    var dotColor = UIColor.ud.iconN3 {
        didSet {
            dotView.backgroundColor = dotColor
        }
    }

    var state: State = .normal {
        didSet {
            updateDotSize(state: state)
        }
    }

    var animateDuration: TimeInterval = 0.3

    init(config: ItemConfig, index: Int) {

        self.itemWidth = config.itemWidth
        self.dotSize = config.dotSize
        self.verticalPadding = config.verticalPadding
        self.mediumDotSize = config.mediumDotSize
        self.smallDotSize = config.smallDotSize
        self.index = index

        let x = itemWidth * CGFloat(index)
        let frame = CGRect(x: x, y: 0, width: itemWidth, height: dotSize + verticalPadding * 2)

        super.init(frame: frame)

        backgroundColor = UIColor.clear

        dotView.frame.size = CGSize(width: dotSize, height: dotSize)
        dotView.center = CGPoint(x: itemWidth / 2, y: dotSize / 2 + verticalPadding)
        dotView.backgroundColor = dotColor
        dotView.layer.cornerRadius = dotSize / 2
        dotView.layer.masksToBounds = true

        addSubview(dotView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: private

    private let dotView = UIView()

    private let itemWidth: CGFloat
    private let verticalPadding: CGFloat

    private let dotSize: CGFloat

    private let mediumDotSize: CGFloat

    private let smallDotSize: CGFloat

    private func updateDotSize(state: State) {

        var size: CGSize

        switch state {
        case .normal:
            size = CGSize(width: dotSize, height: dotSize)
        case .medium:
            size = CGSize(width: mediumDotSize, height: mediumDotSize)
        case .small:
            size = CGSize(width: smallDotSize, height: smallDotSize)
        case .none:
            size = CGSize.zero
        }

        UIView.animate(withDuration: animateDuration, animations: { [unowned self] in
            self.dotView.layer.cornerRadius = size.height / 2.0
            self.dotView.layer.bounds.size = size
        })
    }
}
