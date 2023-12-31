//
//  FontSettingView.swift
//  LarkMine
//
//  Created by bytedance on 2020/11/12.
//

import Foundation
import UIKit
import LarkZoomable
import UniverseDesignFont

final class FontSettingView: UIView {

    lazy var exampleViews: [UIView] = [messageView, docView]

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.bounces = false
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = UIColor.ud.bgBody
        return scrollView
    }()

    private lazy var bottomWrapper: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var bottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var messageView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        return tableView
    }()

    lazy var chatView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        return tableView
    }()

    lazy var docView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.alwaysBounceVertical = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        return tableView
    }()

    lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.hidesForSinglePage = true
        pageControl.pageIndicatorTintColor = UIColor.ud.N300
        pageControl.currentPageIndicatorTintColor = UIColor.ud.colorfulBlue
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()

    lazy var rulerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    lazy var zoomSlider: ZoomSlider = {
        let slider = ZoomSlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()

    private lazy var minLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.text = "A"
        Zoom.allCases.first.flatMap { label.font = UDFont.getTitle4(for: $0) }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var maxLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.text = "A"
        Zoom.allCases.last.flatMap { label.font = UDFont.getTitle4(for: $0) }
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var normalLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.text = BundleI18n.LarkMine.Lark_NewSettings_DefaultTextSize
        label.font = UDFont.getTitle4(for: .normal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addSubview(scrollView)
        addSubview(bottomWrapper)
        addSubview(pageControl)
        for exampleView in exampleViews {
            scrollView.addSubview(exampleView)
        }
        bottomWrapper.addSubview(bottomView)
        bottomView.addSubview(rulerImageView)
        bottomView.addSubview(zoomSlider)
        bottomView.addSubview(minLabel)
        bottomView.addSubview(maxLabel)
        bottomView.addSubview(normalLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leftAnchor.constraint(equalTo: leftAnchor),
            scrollView.rightAnchor.constraint(equalTo: rightAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomView.topAnchor)
        ])
        NSLayoutConstraint.activate([
            bottomWrapper.topAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -100),
            bottomWrapper.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomWrapper.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomWrapper.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
        NSLayoutConstraint.activate([
            bottomView.topAnchor.constraint(equalTo: bottomWrapper.topAnchor),
            bottomView.bottomAnchor.constraint(equalTo: bottomWrapper.bottomAnchor),
            bottomView.trailingAnchor.constraint(equalTo: bottomWrapper.trailingAnchor),
            bottomView.leadingAnchor.constraint(equalTo: bottomWrapper.leadingAnchor)
        ])
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10)
        ])
        NSLayoutConstraint.activate([
            zoomSlider.leadingAnchor.constraint(equalTo: bottomView.leadingAnchor, constant: 27),
            zoomSlider.trailingAnchor.constraint(equalTo: bottomView.trailingAnchor, constant: -27),
            zoomSlider.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -15)
        ])
        let thumbWidth = zoomSlider.thumbRect(forBounds: .zero, trackRect: .zero, value: zoomSlider.minimumValue).width
        NSLayoutConstraint.activate([
            rulerImageView.leadingAnchor.constraint(equalTo: zoomSlider.leadingAnchor, constant: thumbWidth / 2),
            rulerImageView.trailingAnchor.constraint(equalTo: zoomSlider.trailingAnchor, constant: -thumbWidth / 2),
            rulerImageView.topAnchor.constraint(equalTo: zoomSlider.topAnchor),
            rulerImageView.bottomAnchor.constraint(equalTo: zoomSlider.bottomAnchor)
        ])

        let zoomLevels = Zoom.allCases
        guard let regularIndex = zoomLevels.firstIndex(where: { $0 == .normal }) else { return }
        NSLayoutConstraint.activate([
            minLabel.lastBaselineAnchor.constraint(equalTo: zoomSlider.topAnchor, constant: -8),
            maxLabel.lastBaselineAnchor.constraint(equalTo: minLabel.lastBaselineAnchor),
            normalLabel.lastBaselineAnchor.constraint(equalTo: minLabel.lastBaselineAnchor),
            minLabel.centerXAnchor.constraint(equalTo: rulerImageView.leadingAnchor, constant: -2),
            maxLabel.centerXAnchor.constraint(equalTo: rulerImageView.trailingAnchor, constant: 2),
            NSLayoutConstraint(item: normalLabel,
                               attribute: .centerX,
                               relatedBy: .equal,
                               toItem: rulerImageView,
                               attribute: .trailingMargin,
                               multiplier: CGFloat(regularIndex) / CGFloat(zoomLevels.count - 1),
                               constant: 0
            )
        ])
    }

    private func setupAppearance() {
        scrollView.delegate = self
        pageControl.addTarget(self, action: #selector(didTapPageControl(_:)), for: .valueChanged)
        pageControl.numberOfPages = exampleViews.count

        bottomWrapper.layer.shadowColor = UIColor.ud.staticBlack.cgColor
        bottomWrapper.layer.shadowOffset = CGSize(width: 0, height: -2)
        bottomWrapper.layer.shadowRadius = 2
        bottomWrapper.layer.shadowOpacity = 0.04
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.contentSize = CGSize(
            width: self.bounds.width * CGFloat(exampleViews.count),
            height: scrollView.bounds.height
        )
        for (i, view) in exampleViews.enumerated() {
            view.frame = CGRect(
                x: self.bounds.width * CGFloat(i),
                y: 0,
                width: self.bounds.width,
                height: scrollView.bounds.height
            )
        }
    }

}

extension FontSettingView: UIScrollViewDelegate {

    @objc
    private func didTapPageControl(_ sender: UIPageControl) {
        let page = CGFloat(sender.currentPage)
        scrollView.setContentOffset(CGPoint(x: frame.width * page, y: 0), animated: true)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / frame.width)
        pageControl.currentPage = page
    }

}
