//
//  FlameView.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/21.
//

import Foundation
import UniverseDesignColor

final class WaveView: UIView {
    enum DisplatState {
        case reset
        case start
        case stop
    }

    private var dataArray: [Int] = []
    private var displayArr: [Int] = []
    private var placeArr: [Int] = []
    private var buffer: [Int] = []
    private var originSize: CGSize = .zero
    private var timer: Timer?
    private var flameCount: Int = 0
    private var displayState: DisplatState = .reset
    private var flameColor: UIColor = UDColor.functionInfoContentDefault {
        didSet {
            tableView.reloadData()
        }
    }

    private let tableView = UITableView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        // 隐藏拖动条
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = UIColor.clear
        // 隐藏分割线
        tableView.separatorStyle = .none
        tableView.isUserInteractionEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AudioWaveCell.self, forCellReuseIdentifier: "table_cell")
        self.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        reset()
    }

    func reset() {
        displayState = .reset
        timer?.invalidate()
        timer = nil
        placeArr = Array(repeating: 0, count: flameCount)
        dataArray = []
        displayArr = []
        buffer = []
        tableView.reloadData()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard self.bounds.size != originSize else { return }
        originSize = self.bounds.size
        flameCount = Int(originSize.height / 4) + 5
        if displayState == .stop {
            stop()
        } else {
            placeArr = Array(repeating: 0, count: flameCount)
            tableView.reloadData()
            tableviewToBottom(animation: false)
        }
    }

    private func tableviewToBottom(animation: Bool = true) {
        if animation {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveLinear) {[weak self] in
                guard let self else { return }
                self.tableView.scrollToRow(at: IndexPath(item: self.displayArr.count + self.placeArr.count - 1, section: 0), at: .bottom, animated: false)
            }
        } else {
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentSize.height - self.tableView.frame.size.height), animated: false)
        }
    }

    @objc
    private func timerP() {
        var indexPaths: [IndexPath] = []
        let prefixNum = buffer.count >= 4 ? 4 : buffer.count
        let temp = buffer.prefix(prefixNum)
        buffer = buffer.suffix(buffer.count - prefixNum)
        for i in temp {
            dataArray.append(i)
            displayArr.append(i)
            indexPaths.append(IndexPath(item: displayArr.count + placeArr.count - 1, section: 0))
        }
        guard !indexPaths.isEmpty else { return }
        tableView.insertRows(at: indexPaths, with: .bottom)
        tableviewToBottom()
    }

    private func transformation(x: Float) -> Float {
        if x < 50 {
            return max((x / 10) - Float.random(in: 0...2), 0)
        }
        let n = x - 50
        let xt = (n - 20) / 10
        let height = 26 / (1 + exp(-xt)) + 5
        let new = disturb(x: height, maxValue: 26)
        return max(1, min(26, new))
    }

    private func disturb(x: Float, maxValue: Float) -> Float {
        let maxDiff = maxValue / 5
        if x / maxValue >= 0.9 {    // x 接近最大值时
            return x - maxDiff * Float.random(in: 0...1)
        }
        return x
    }

    func addDecible(_ decibel: Float) {
        guard displayState == .start else { return }
        let newDecibel = Int(transformation(x: decibel))
        buffer.append(newDecibel)
    }

    func stop() {
        displayState = .stop
        timer?.invalidate()
        timer = nil

        guard !dataArray.isEmpty, tableView.numberOfRows(inSection: 0) > 0 else { return }
        tableView.scrollToRow(at: IndexPath(item: 0, section: 0), at: .top, animated: false)
        placeArr = []
        displayArr = calculateDisplayArray()
        tableView.reloadData()
    }

    func changeColor(color: UIColor) {
        flameColor = color
    }

    func start() {
        guard displayState != .start else { return }
        displayState = .start
        timer = Timer(timeInterval: 0.2, target: self, selector: #selector(timerP), userInfo: nil, repeats: true)
        if let timer { RunLoop.current.add(timer, forMode: .default) }
    }

    private func calculateDisplayArray() -> [Int] {
        let waveRealLength = dataArray.count
        let countInScreen = flameCount
        let ratio = CGFloat(waveRealLength) / CGFloat(countInScreen)
        var displayArr: [Int] = []
        for i in 0..<countInScreen {
            var indexStart = Int(ratio * CGFloat(i))
            let indexEnd = Int(ratio * CGFloat(i + 1))
            var scaleHeight = 0
            var itemCount: Int = 1
            while indexStart < indexEnd && indexStart < waveRealLength {
                scaleHeight += dataArray[indexStart]
                indexStart += 1
                itemCount += 1
            }
            itemCount = itemCount > 1 ? itemCount - 1 : 1
            displayArr.append(scaleHeight / itemCount)
        }
        if waveRealLength < countInScreen {
            displayArr = average(array: displayArr)

            let rever = Array(displayArr.reversed())
            displayArr = average(array: rever)
            displayArr = Array(displayArr.reversed())
        }
        // 每个值大于等于0
        displayArr = displayArr.map({ max($0, 0) })
        return displayArr
    }

    // 取左右两边的最大的值的二分之一，作为当前值
    private func average(array: [Int]) -> [Int] {
        var displayArray: [Int] = []
        for (i, n) in array.enumerated() {
            let next: Int = (i + 1) < array.count ? array[i + 1] : 0
            let last: Int = displayArray.last ?? 0
            if n <= next, n < last {
                if next > last {
                    displayArray.append(Int(next / 2))
                } else {
                    displayArray.append(Int(last / 2))
                }
            } else {
                displayArray.append(n)
            }
        }
        return displayArray
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
extension WaveView: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayArr.count + placeArr.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "table_cell", for: indexPath) as? AudioWaveCell else { return AudioWaveCell() }
        if indexPath.row < placeArr.count {
            cell.setIndex(placeArr[indexPath.row], color: UDColor.functionInfoContentLoading)
        } else if indexPath.row < placeArr.count + displayArr.count {
            cell.setIndex(displayArr[indexPath.row - placeArr.count], color: flameColor)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 4
    }
}

class AudioWaveCell: UITableViewCell {

    private let clayer: CAShapeLayer = {
        let l = CAShapeLayer()
        return l
    }()
    private let arcPath = UIBezierPath()
    func setIndex(_ width: Int, color: UIColor) {
        self.backgroundColor = .clear
        arcPath.removeAllPoints()
        let width: Double = Double(width)
        arcPath.move(to: CGPoint(x: 14 + width / 2, y: 0))
        arcPath.addArc(withCenter: CGPoint(x: 14 + width / 2, y: 1), radius: 1, startAngle: -CGFloat.pi * 0.5, endAngle: CGFloat.pi * 0.5, clockwise: true)
        arcPath.addLine(to: CGPoint(x: (28 - width) / 2, y: 2))
        arcPath.addArc(withCenter: CGPoint(x: (28 - width) / 2, y: 1), radius: 1, startAngle: CGFloat.pi * 0.5, endAngle: -CGFloat.pi * 0.5, clockwise: true)
        arcPath.close()

        clayer.path = arcPath.cgPath
        clayer.fillColor = color.cgColor
        self.layer.addSublayer(clayer)
    }
}
