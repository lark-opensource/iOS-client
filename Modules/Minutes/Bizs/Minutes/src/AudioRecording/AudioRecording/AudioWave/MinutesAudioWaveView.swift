//
//  MinutesAudioWaveView.swift
//  Minutes
//
//  Created by panzaofeng on 2021/3/11.
//

import UIKit
import MinutesFoundation
import UniverseDesignColor

class MinutesAudioWaveCell: UICollectionViewCell {
    static let MaxHeight: CGFloat = 56
    static let LineSpacing: CGFloat = 3
    static let LineWidth: CGFloat = 2

    lazy var path: UIBezierPath = {
        let path = UIBezierPath()
        return path
    }()

    private var index: Int = 0

    private var point: CGFloat = 0.1

    private var decibelView: UIView = {
        let view = UIView()
        return view
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    func setIndex(_ index: Int, point: CGFloat, isPaused: Bool) {
        self.index = index
        if isPaused {
            decibelView.backgroundColor = UIColor.ud.iconN3.nonDynamic
        } else {
            decibelView.backgroundColor = UIColor.ud.primaryContentDefault.nonDynamic
        }
        self.point = point
        if self.point < 0.06 {
            self.point = 0.06
        }
        if self.point > 1 {
            self.point = 1
        }
        let height = self.point * MinutesAudioWaveCell.MaxHeight
        decibelView.frame = CGRect(x: 0, y: (MinutesAudioWaveCell.MaxHeight - height) / 2, width: 2, height: height)
        self.addSubview(decibelView)
    }
}

class MinutesAudioWaveView: UICollectionView {

    private var viewModel: MinutesAudioWaveViewModel

    private var isPaused: Bool = false

    private let cellReuseIdentifier = String(describing: MinutesAudioWaveCell.self)

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        viewModel = MinutesAudioWaveViewModel()
        super.init(frame: frame, collectionViewLayout: layout)
        self.register(MinutesAudioWaveCell.self, forCellWithReuseIdentifier: MinutesAudioWaveCell.description())
        self.register(AudioWaveViewHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: String(describing: AudioWaveViewHeaderView.self))
        self.delegate = self
        self.dataSource = self
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.isUserInteractionEnabled = false
        self.bounces = false
        viewModel.delegate = self

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadWave() {
        let index = viewModel.audioDecibelData.pointsArray.count
        if index > 0 {
            self.reloadData()
            self.layoutIfNeeded()
            let endOffset = CGPoint(x: self.contentSize.width - self.bounds.width, y: 0)
            self.setContentOffset(endOffset, animated: false)
        }
    }

    func startWave() {
        isPaused = false
    }

    func stopWave() {
        isPaused = true
        self.reloadData()
    }
}

extension MinutesAudioWaveView: UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.audioDecibelData.pointsArray.count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                       withReuseIdentifier: String(describing: AudioWaveViewHeaderView.self),
                                                                       for: indexPath)
            return view
        } else {
             return UICollectionReusableView()
        }
    }
}

extension MinutesAudioWaveView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = (MinutesAudioWaveCell.LineWidth + MinutesAudioWaveCell.LineSpacing)
        return CGSize(width: width, height: MinutesAudioWaveCell.MaxHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.bounds.width, height: MinutesAudioWaveCell.MaxHeight)
    }
}

extension MinutesAudioWaveView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MinutesAudioWaveCell.description(), for: indexPath) as? MinutesAudioWaveCell else {
            return UICollectionViewCell()
        }
        if indexPath.row < viewModel.audioDecibelData.pointsArray.count {
            let point = viewModel.audioDecibelData.pointsArray[indexPath.row]
            cell.setIndex(indexPath.row, point: point, isPaused: isPaused)
        }
        return cell
    }
}

extension MinutesAudioWaveView: MinutesAudioWaveViewModelDelegate {
    func audioPointsDidUpdate() {
        self.reloadData()
        self.layoutIfNeeded()
        let endOffset = CGPoint(x: self.contentSize.width - self.bounds.width, y: 0)
        self.setContentOffset(endOffset, animated: false)
    }
    
    func audioPointsDidAdd(_ index: Int) {
        self.reloadData()
        self.layoutIfNeeded()
        let endOffset = CGPoint(x: self.contentSize.width - self.bounds.width, y: 0)
        self.setContentOffset(endOffset, animated: false)
    }
}

private class AudioWaveViewHeaderView: UICollectionReusableView {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
