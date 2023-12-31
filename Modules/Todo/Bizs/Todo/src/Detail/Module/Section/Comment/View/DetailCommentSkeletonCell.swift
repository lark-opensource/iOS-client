//
//  DetailCommentSkeletonCell.swift
//  Todo
//
//  Created by 张威 on 2021/3/11.
//

import SkeletonView
import LarkUIKit

class DetailCommentSkeletonCell: UITableViewCell {

    private let gradient = SkeletonGradient(
        baseColor: UIColor.ud.bgFiller.withAlphaComponent(0.5),
        secondaryColor: UIColor.ud.bgFiller.withAlphaComponent(0.8)
    )
    static let desiredHeight: CGFloat = 64

    private var isAnimating = false

    private let circleView = UIView()
    private let barView1 = UIView()
    private let barView2 = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = UIColor.ud.bgBody
        isSkeletonable = true

        circleView.frame = CGRect(x: 16, y: 12, width: 40, height: 40)
        circleView.layer.cornerRadius = 20
        circleView.clipsToBounds = true
        contentView.addSubview(circleView)
        circleView.isSkeletonable = true

        barView1.frame = CGRect(x: 66, y: 17, width: 90, height: 10)
        barView1.layer.cornerRadius = 2
        barView1.clipsToBounds = true
        barView1.isSkeletonable = true
        contentView.addSubview(barView1)

        barView2.frame = CGRect(x: 66, y: 36, width: 260, height: 10)
        barView2.layer.cornerRadius = 2
        barView2.clipsToBounds = true
        barView2.isSkeletonable = true
        contentView.addSubview(barView2)

        showAnimatedGradientSkeleton(usingGradient: gradient)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        barView2.frame.size.width = bounds.width - barView2.frame.left - 49
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func startAnimationIfNeeded() {
        guard !isAnimating else { return }
        isAnimating = true
        startSkeletonAnimation()
    }

}
