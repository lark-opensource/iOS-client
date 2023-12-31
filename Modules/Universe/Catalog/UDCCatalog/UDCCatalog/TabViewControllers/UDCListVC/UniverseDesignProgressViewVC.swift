//
//  UniverseDesignProgressViewVC.swift
//  UDCCatalog
//
//  Created by CJ on 2021/1/6.
//  Copyright © 2021 CJ. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignProgressView
import UniverseDesignColor

class UniverseDesignProgressViewVC: UIViewController, UITableViewDataSource {
    var titles: [String] = []
    var dataSource: [UDProgressView] = []
    var timer: Timer?
    var counter: CGFloat = 0.0
    
    private lazy var slider: UISlider = {
        let slider = UISlider()
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        return slider
    }()
    
    private lazy var startButton: UIButton = {
        let button = UIButton()
        button.setTitle("开始", for: .normal)
        button.backgroundColor = .gray
        button.addTarget(self, action: #selector(clickStartButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var stopButton: UIButton = {
        let button = UIButton()
        button.setTitle("停止", for: .normal)
        button.backgroundColor = .gray
        button.addTarget(self, action: #selector(clickStopButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton()
        button.setTitle("重置", for: .normal)
        button.backgroundColor = .gray
        button.addTarget(self, action: #selector(clickResetButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var errorButton: UIButton = {
        let button = UIButton()
        button.setTitle("错误", for: .normal)
        button.backgroundColor = .gray
        button.addTarget(self, action: #selector(clickErrorButton), for: .touchUpInside)
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.backgroundColor = .clear
        tableView.register(UniverseDesignProgressViewCell.self, forCellReuseIdentifier: UniverseDesignProgressViewCell.cellIdentifier)
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UniverseDesignProgressViewVC"
        view.backgroundColor = UDColor.bgBase
        setupDataSource()
        setupUI()
    }
    
    private func setupDataSource() {
        let defaultProgressView = UDProgressView()
        let progressView2 = UDProgressView(config: UDProgressViewUIConfig(type: .linear, barMetrics: .default, layoutDirection: .vertical, showValue: false))
        let progressView3 = UDProgressView(config: UDProgressViewUIConfig(type: .linear, barMetrics: .regular, layoutDirection: .horizontal, showValue: false))
        let progressView4 = UDProgressView(config: UDProgressViewUIConfig(type: .linear, barMetrics: .regular, layoutDirection: .vertical, showValue: false))
        let progressView5 = UDProgressView(config: UDProgressViewUIConfig(type: .linear, barMetrics: .default, layoutDirection: .horizontal, showValue: true))
        let progressView6 = UDProgressView(config: UDProgressViewUIConfig(type: .linear, barMetrics: .default, layoutDirection: .vertical, showValue: true))
        let progressView7 = UDProgressView(config: UDProgressViewUIConfig(type: .linear, barMetrics: .regular, layoutDirection: .horizontal, showValue: true))
        let progressView8 = UDProgressView(config: UDProgressViewUIConfig(type: .linear, barMetrics: .regular, layoutDirection: .vertical, showValue: true))
        
        let progressView9 = UDProgressView(config: UDProgressViewUIConfig(type: .circular, layoutDirection: . horizontal, showValue: false))
        let progressView10 = UDProgressView(config: UDProgressViewUIConfig(type: .circular, layoutDirection: . vertical, showValue: false))
        let progressView11 = UDProgressView(config: UDProgressViewUIConfig(type: .circular, layoutDirection: . horizontal, showValue: true))
        let progressView12 = UDProgressView(config: UDProgressViewUIConfig(type: .circular, layoutDirection: . vertical, showValue: true))
        let layoutConfig = UDProgressViewLayoutConfig(circleProgressWidth: 16)
        let progressView13 = UDProgressView(config: UDProgressViewUIConfig(type: .circular, layoutDirection: . horizontal, themeColor: UDProgressViewThemeColor.maskThemeColor, showValue: true))
        let progressView14 = UDProgressView(config: UDProgressViewUIConfig(type: .circular, layoutDirection: . vertical, themeColor: UDProgressViewThemeColor.maskThemeColor, showValue: true), layoutConfig: layoutConfig)
        
        dataSource = [defaultProgressView, progressView2,
                      progressView3, progressView4,
                      progressView5, progressView6,
                      progressView7, progressView8,
                      progressView9, progressView10,
                      progressView11, progressView12,
                      progressView13, progressView14,
        ]
        titles = ["线性+水平+小尺寸(默认)", "线性+垂直+小尺寸",
                  "线性+水平+大尺寸", "线性+垂直+大尺寸",
                  "线性+水平+小尺寸+进度值", "线性+垂直+小尺寸+进度值",
                  "线性+水平+大尺寸+进度值", "线性+垂直+大尺寸+进度值",
                  "环形+水平", "环形+垂直",
                  "环形+水平+进度值", "环形+垂直+进度值",
                  "环形+水平+进度值+遮罩", "环形+垂直+进度值+遮罩"
        ]
    }
    
    private func setupUI() {
        view.addSubview(slider)
        view.addSubview(startButton)
        view.addSubview(stopButton)
        view.addSubview(resetButton)
        view.addSubview(errorButton)
        view.addSubview(tableView)
        setupConstraints()
    }
    
    private func setupConstraints() {
        slider.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.top.equalTo(100)
        }
        
        startButton.snp.makeConstraints { (make) in
            make.top.equalTo(slider.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }
        
        stopButton.snp.makeConstraints { (make) in
            make.leading.equalTo(startButton.snp.trailing).offset(20)
            make.centerY.width.equalTo(startButton)
        }
        
        resetButton.snp.makeConstraints { (make) in
            make.leading.equalTo(stopButton.snp.trailing).offset(20)
            make.centerY.width.equalTo(startButton)
        }
        
        errorButton.snp.makeConstraints { (make) in
            make.leading.equalTo(resetButton.snp.trailing).offset(20)
            make.centerY.width.equalTo(startButton)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        tableView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(startButton.snp.bottom).offset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: UniverseDesignProgressViewCell.cellIdentifier) as? UniverseDesignProgressViewCell {
            if indexPath.row < titles.count {
                cell.titleLabel.text = titles[indexPath.row]
            }
            if indexPath.row < dataSource.count {
                let progressView = dataSource[indexPath.row]
                cell.removeAccessoryView()
                cell.addAccessoryView(progressView)
                cell.backgroundColor = (indexPath.row >= dataSource.count - 2) ? .gray : .clear
            }
            
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: UniverseDesignProgressViewCell.cellIdentifier)
        }
    }
    
    @objc private func sliderValueChanged() {
        updateProgressView(value: CGFloat(slider.value))
    }
    
    @objc private func clickStartButton() {
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] (_) in
                guard let self = self else { return }
                self.counter += 0.02
                self.updateProgressView(value: self.counter)
                if self.counter >= 1 {
                    self.invalidateTimer()
                }
            }
        }
    }
    
    @objc private func clickStopButton() {
        invalidateTimer()
    }
    
    @objc private func clickResetButton() {
        invalidateTimer()
        counter = 0.0
        updateProgressView(value: 0.0)
    }
    
    @objc private func clickErrorButton() {
        invalidateTimer()
        dataSource.forEach { (progressView) in
            progressView.setProgressLoadFailed()
        }
    }
    
    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateProgressView(value: CGFloat) {
        self.counter = value
        dataSource.forEach { (progressView) in
            progressView.setProgress(value, animated: true)
        }
    }
}

class UniverseDesignProgressViewCell: UITableViewCell {
    static let cellIdentifier = "progressViewDemoCell"
    public let titleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(titleLabel)
        titleLabel.textAlignment = .left
        titleLabel.font = UIFont.ud.caption1
        titleLabel.textColor = UDColor.textColor
        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.equalTo(150)
            make.leading.equalToSuperview().offset(5)
        }
    }
    
    public func removeAccessoryView() {
        contentView.subviews.forEach { (view) in
            if view.isKind(of: UDProgressView.self) {
                view.removeFromSuperview()
            }
        }
    }
    
    public func addAccessoryView(_ view: UIView) {
        contentView.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.leading.equalTo(titleLabel.snp.trailing).offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()

        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
