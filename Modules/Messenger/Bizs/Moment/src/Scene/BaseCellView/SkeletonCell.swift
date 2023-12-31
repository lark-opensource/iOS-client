//
//  SkeletonlCell.swift
//  Moment
//
//  Created by zc09v on 2021/1/27.
//

import Foundation
import UIKit

protocol SkeletonCell: UITableViewCell {
    func addCirleView(size: CGFloat, top: CGFloat, left: CGFloat)
    func addCirleView(size: CGFloat, top: CGFloat, right: CGFloat)
    func addBar(left: CGFloat, topOffset: CGFloat, right: CGFloat, height: CGFloat)
    func addBar(left: CGFloat, topOffset: CGFloat, width: CGFloat, height: CGFloat)
    func addBar(right: CGFloat, topOffset: CGFloat, width: CGFloat, height: CGFloat)
}

extension SkeletonCell {
    func addCirleView(size: CGFloat, top: CGFloat, left: CGFloat) {
        contentView.addSkeletonCirleView(size: size, top: top, left: left)
    }

    func addCirleView(size: CGFloat, top: CGFloat, right: CGFloat) {
        contentView.addSkeletonCirleView(size: size, top: top, right: right)
    }

    func addBar(left: CGFloat, topOffset: CGFloat, right: CGFloat, height: CGFloat) {
        contentView.addSkeletonBar(left: left, topOffset: topOffset, right: right, height: height)
    }

    func addBar(left: CGFloat, topOffset: CGFloat, width: CGFloat, height: CGFloat) {
        contentView.addSkeletonBar(left: left, topOffset: topOffset, width: width, height: height)
    }

    func addBar(right: CGFloat, topOffset: CGFloat, width: CGFloat, height: CGFloat) {
        contentView.addSkeletonBar(right: right, topOffset: topOffset, width: width, height: height)
    }
}
extension UIView {
    func addSkeletonCirleView(size: CGFloat, top: CGFloat, left: CGFloat) {
        let view = UIView()
        view.layer.cornerRadius = size / 2
        view.clipsToBounds = true
        addSubview(view)
        view.snp.makeConstraints { (make) in
            make.width.height.equalTo(size)
            make.left.equalToSuperview().offset(left)
            make.top.equalToSuperview().offset(top)
        }
        view.isSkeletonable = true
    }

    func addSkeletonCirleView(size: CGFloat, top: CGFloat, right: CGFloat) {
        let view = UIView()
        view.layer.cornerRadius = size / 2
        view.clipsToBounds = true
        addSubview(view)
        view.snp.makeConstraints { (make) in
            make.width.height.equalTo(size)
            make.right.equalToSuperview().offset(-right)
            make.top.equalToSuperview().offset(top)
        }
        view.isSkeletonable = true
    }

    func addSkeletonBar(left: CGFloat, topOffset: CGFloat, right: CGFloat, height: CGFloat) {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        addSubview(view)
        view.snp.makeConstraints { (make) in
            make.height.equalTo(height)
            make.left.equalToSuperview().offset(left)
            make.right.equalToSuperview().offset(-right)
            make.top.equalToSuperview().offset(topOffset)
        }
        view.isSkeletonable = true
    }

    func addSkeletonBar(left: CGFloat, topOffset: CGFloat, width: CGFloat, height: CGFloat) {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        addSubview(view)
        view.snp.makeConstraints { (make) in
            make.height.equalTo(height)
            make.left.equalToSuperview().offset(left)
            make.width.equalTo(width)
            make.top.equalToSuperview().offset(topOffset)
        }
        view.isSkeletonable = true
    }

    func addSkeletonBar(right: CGFloat, topOffset: CGFloat, width: CGFloat, height: CGFloat) {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        addSubview(view)
        view.snp.makeConstraints { (make) in
            make.height.equalTo(height)
            make.right.equalToSuperview().offset(-right)
            make.width.equalTo(width)
            make.top.equalToSuperview().offset(topOffset)
        }
        view.isSkeletonable = true
    }
}
