//
//  ReactionToastView.swift
//  Minutes
//
//  Created by lvdaqian on 2021/3/1.
//

import Foundation
import UniverseDesignColor

class ReactionToastView: UIView {

    let maxContentWidth: CGFloat = 244
    let lineHeight: CGFloat = 36

    var realContentWidth: CGFloat = 0

    var lines: [UIView] = []
    var currentLineIndex: Int = 0
    var delayTime: Int = 300

    var reactionViews: [ReactionView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        backgroundColor = UIColor.ud.bgTips
        layer.cornerRadius = 18
        clipsToBounds = true
        isUserInteractionEnabled = false
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: realContentWidth + lineHeight, height: lineHeight)
    }

    func addlines(_ models: [ReactionViewModel]) {

        reactionViews = models.map { ReactionView($0) }

        lines.forEach { $0.removeFromSuperview() }
        lines.removeAll()

        var index = 0
        let max = reactionViews.count

        while index < max {
            let stackView = UIStackView()
            stackView.distribution = .equalSpacing
            stackView.axis = .horizontal
            stackView.spacing = 10

            while index < max {
                let view = reactionViews[index]
                stackView.addArrangedSubview(view)
                if stackView.systemLayoutSizeFitting(.zero).width > maxContentWidth {
                    stackView.removeArrangedSubview(view)
                    break
                }
                index = index + 1
            }
            lines.append(stackView)
            let width = stackView.systemLayoutSizeFitting(.zero).width
            if width > realContentWidth {
                realContentWidth = width
            }
        }

        var lineIndex = 0

        lines.forEach { line in
            addSubview(line)
            line.snp.makeConstraints { maker in
                maker.centerX.equalToSuperview()
                maker.top.equalToSuperview().offset(lineHeight * CGFloat(lineIndex))
                maker.height.equalTo(lineHeight)
            }
            lineIndex = lineIndex + 1
        }

        currentLineIndex = 0
        bounds = CGRect(origin: .zero, size: intrinsicContentSize)
        invalidateIntrinsicContentSize()
        play()
    }

    func play() {
        if lines.count > 1 {
            let delayTime: Int = 3000 / lines.count
            self.delayTime = max(delayTime, self.delayTime)

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.delayTime)) {
                self.playNext()
            }
        }
    }

    func playNext() {
        guard currentLineIndex < lines.count - 1 else {
            currentLineIndex = 0
            return
        }

        let line = lines[currentLineIndex]
        currentLineIndex = currentLineIndex + 1
        let offsetY = CGFloat(currentLineIndex) * lineHeight
        var bounds = CGRect(origin: CGPoint(x: 0, y: offsetY), size: self.bounds.size)
        UIView.animate(withDuration: 0.25,
                       animations: {
                            self.bounds = bounds
                            line.alpha = 0
                       },
                       completion: { _ in
                            line.alpha = 1
                       })

        if currentLineIndex < lines.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(self.delayTime)) {
                self.playNext()
            }
        }
    }

}
