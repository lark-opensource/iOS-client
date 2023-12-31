//
//  MinutesAudioWaveContainer.swift
//  Minutes
//
//  Created by panzaofeng on 2021/3/11.
//

import UIKit
import MinutesFoundation

class MinutesAudioWaveContainer: UIView {

    private var collectionLayout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        return layout
    }

    lazy var waveView: MinutesAudioWaveView = {
        let view = MinutesAudioWaveView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: 0), collectionViewLayout: collectionLayout)
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(waveView)
        waveView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview()
            maker.right.equalToSuperview().offset(20)
            maker.top.equalToSuperview().offset(16)
            maker.bottom.equalToSuperview().offset(-4)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopWave()
    }

    public func loadWave() {
        waveView.loadWave()
    }

    public func startWave() {
        waveView.startWave()
    }

    public func stopWave() {
        waveView.stopWave()
    }

    public func clearData() {
        MinutesAudioRecorder.shared.decibelData.clearDecibelData()
    }
}
