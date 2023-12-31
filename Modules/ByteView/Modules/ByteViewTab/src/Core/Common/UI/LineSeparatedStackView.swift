//
//  LineSeparatedStackView.swift
//  ByteViewTab
//
//  Created by Juntong Chen on 2021/8/26.
//

import Foundation

class LineSeparatedStackView: UIStackView {

    var lineWidth: CGFloat = 1.0
    var lineHeight: CGFloat = 10.0
    var stackHeight: CGFloat = 20.0
    var lineColor: UIColor = .ud.lineDividerDefault

    var separatedSubviews: [UIView?] {
        get {
            return self.arrangedSubviews.map {
                if let container = $0 as? DescContainerView {
                    return container.content
                } else {
                    return $0
                }
            }
        }
        set {
            self.arrangedSubviews.forEach {
                $0.removeFromSuperview()
            }
            for view in newValue {
                self.addSeparatedSubview(view)
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    init(separatedSubviews: [UIView]) {
        super.init(frame: .zero)
        for view in separatedSubviews {
            self.addSeparatedSubview(view)
        }
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    @discardableResult
    func addSeparatedSubview(_ view: UIView?) -> UIView? {
        guard let view = view else { return nil }
        let lineView = createLineView()
        let containerView = DescContainerView(lineView: lineView,
                                              spacing: spacing,
                                              content: view,
                                              showLine: !self.arrangedSubviews.isEmpty)
        containerView.snp.makeConstraints {
            $0.height.equalTo(stackHeight).priority(.low)
        }
        self.addArrangedSubview(containerView)
        return containerView
    }

    @discardableResult
    func insertSeparatedSubview(_ view: UIView?, at index: Int) -> UIView? {
        guard let view = view else { return nil }
        guard index < self.arrangedSubviews.count else { return nil }

        let lineView = createLineView()
        let containerView = DescContainerView(lineView: lineView,
                                              spacing: spacing,
                                              content: view,
                                              showLine: !self.arrangedSubviews.isEmpty)
        containerView.snp.makeConstraints {
            $0.height.equalTo(stackHeight)
        }
        self.insertArrangedSubview(containerView, at: index)
        layoutContainers()
        return containerView
    }

    func removeSeparatedSubview(_ view: UIView) {
        if let containerView = self.arrangedSubviews.compactMap({ $0 as? DescContainerView }).first(where: { $0.content == view }) {
            containerView.removeFromSuperview()
            layoutContainers()
        }
    }

    func setSubviewHidden(for view: UIView?, hidden: Bool) {
        guard let view = view else { return }
        guard self.arrangedSubviews.contains(view) else { return }
        view.isHidden = hidden
        layoutContainers()
    }

    func layoutContainers() {
        var firstVisibleChecked = false
        for container in self.arrangedSubviews.filter({ !$0.isHidden }).compactMap({ $0 as? DescContainerView }) {
            if !firstVisibleChecked { // 第一个可见视图不应该有分割线
                firstVisibleChecked = true
                container.showLine = false
            } else { // 后续视图左侧都应该有分割线
                container.showLine = true
            }
        }
    }

    private func createLineView() -> UIView {
        let lineView = UIView(frame: .zero)
        lineView.backgroundColor = lineColor
        lineView.snp.makeConstraints {
            $0.width.equalTo(lineWidth)
            $0.height.equalTo(lineHeight)
        }
        return lineView
    }
}


class DescContainerView: UIView {

    var lineView: UIView?
    var content: UIView?
    var spacing: CGFloat = 8.0

    var showLine: Bool = false {
        didSet {
            if showLine != oldValue {
                layoutViews()
            }
        }
    }

    init(lineView: UIView, spacing: CGFloat, content: UIView, showLine: Bool) {
        super.init(frame: .zero)
        self.lineView = lineView
        self.content = content
        self.showLine = showLine
        self.spacing = spacing
        self.addSubview(lineView)
        self.addSubview(content)
        self.lineView?.snp.makeConstraints {
            $0.left.centerY.equalToSuperview()
        }
        layoutViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func layoutViews() {
        guard let lineView = lineView, let content = content else { return }
        if showLine {
            lineView.isHidden = false
            content.snp.remakeConstraints {
                $0.left.equalTo(lineView).offset(spacing)
                $0.right.centerY.equalToSuperview()
            }
        } else {
            lineView.isHidden = true
            content.snp.remakeConstraints {
                $0.left.equalTo(lineView)
                $0.right.centerY.equalToSuperview()
            }
        }
    }
}
