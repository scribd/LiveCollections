//
//  PlayerControl.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/15/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

protocol PlayerControlDelegate: AnyObject {
    func deltaSizeChanged(to size: MovieProviderDeltaSize)
    func playbackRateChanged(to rate: MovieProviderPlaybackRate)
    func playPressed()
    func pausePressed()
    func nextPressed()
}

final class PlayerControl: UIView {
    
    private let stackView = Constants.buildStackView()
    private lazy var deltaControl = { Constants.buildCyclingControl(deltaButton, title: "Delta Size") }()
    private let deltaButton = Constants.buildCyclingButton(MovieProviderDeltaSize.small.rawValue)
    private lazy var rateControl = { Constants.buildCyclingControl(rateButton, title: "Playback Rate") }()
    private let rateButton = Constants.buildCyclingButton(MovieProviderPlaybackRate.slow.rawValue)
    private let playButton = Constants.buildButton("play")
    private let pauseButton = Constants.buildButton("pause")
    private let nextButton = Constants.buildButton("next")
    
    private var delta: MovieProviderDeltaSize = .small
    private var rate: MovieProviderPlaybackRate = .slow

    weak var delegate: PlayerControlDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpSubviews() {
        backgroundColor = .white
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        configureStackViewForPaused()
        
        deltaButton.addTarget(self, action: #selector(deltaPressed), for: .touchUpInside)
        rateButton.addTarget(self, action: #selector(playbackRatePressed), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(playPressed), for: .touchUpInside)
        pauseButton.addTarget(self, action: #selector(pausePressed), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextPressed), for: .touchUpInside)
    }
    
    @objc private func deltaPressed() {
        let nextDelta: MovieProviderDeltaSize
        switch delta {
        case .small: nextDelta = .moderate
        case .moderate: nextDelta = .massive
        case .massive: nextDelta = .small
        }
        delta = nextDelta
        deltaButton.setTitle(delta.rawValue, for: .normal)
        delegate?.deltaSizeChanged(to: delta)
    }

    @objc private func playbackRatePressed() {
        let nextRate: MovieProviderPlaybackRate
        switch rate {
        case .slow: nextRate = .fast
        case .fast: nextRate = .ludicrous
        case .ludicrous: nextRate = .slow
        }
        rate = nextRate
        rateButton.setTitle(rate.rawValue, for: .normal)
        delegate?.playbackRateChanged(to: rate)
    }

    
    @objc private func playPressed() {
        configureStackViewForPlaying()
        delegate?.playPressed()

    }

    @objc private func pausePressed() {
        configureStackViewForPaused()
        delegate?.pausePressed()
    }

    @objc private func nextPressed() {
        pausePressed()
        delegate?.nextPressed()
    }
}

private extension PlayerControl {
    
    func configureStackViewForPlaying() {
        stackView.arrangedSubviews.forEach { subview in
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        stackView.addArrangedSubview(deltaControl)
        stackView.setCustomSpacing(10, after: deltaControl)
        stackView.addArrangedSubview(rateControl)
        stackView.setCustomSpacing(25, after: rateControl)
        stackView.addArrangedSubview(pauseButton)
        stackView.addArrangedSubview(nextButton)
        stackView.setCustomSpacing(50, after: nextButton)
    }

    func configureStackViewForPaused() {
        stackView.arrangedSubviews.forEach { subview in
            stackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }
        stackView.addArrangedSubview(deltaControl)
        stackView.setCustomSpacing(10, after: deltaControl)
        stackView.addArrangedSubview(rateControl)
        stackView.setCustomSpacing(25, after: rateControl)
        stackView.addArrangedSubview(playButton)
        stackView.addArrangedSubview(nextButton)
        stackView.setCustomSpacing(50, after: nextButton)
    }
}

private extension PlayerControl {
    
    struct Constants {

        static func buildCyclingControl(_ button: UIButton, title: String) -> UIView {
            let control = UIView()
            let label = UILabel()
            label.font = .systemFont(ofSize: 12, weight: .bold)
            label.textColor = .darkGray
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = title
            
            control.addSubview(label)
            control.addSubview(button)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: control.topAnchor),
                label.leadingAnchor.constraint(equalTo: control.leadingAnchor),
                label.trailingAnchor.constraint(equalTo: control.trailingAnchor),
                label.heightAnchor.constraint(equalToConstant: 20),

                button.topAnchor.constraint(equalTo: label.bottomAnchor),
                button.leadingAnchor.constraint(equalTo: control.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: control.trailingAnchor),
                button.bottomAnchor.constraint(equalTo: control.bottomAnchor),
                
                control.heightAnchor.constraint(equalToConstant: 50)
            ])
            
            return control
        }
        
        static func buildCyclingButton(_ title: String) -> UIButton {
            let button = UIButton(type: .custom)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .light)
            button.setTitleColor(.darkGray, for: .normal)
            button.layer.borderColor = UIColor.lightGray.cgColor
            button.layer.borderWidth = 1.0
            button.layer.cornerRadius = 4
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 100),
                button.heightAnchor.constraint(equalToConstant: 30)
            ])
            return button
        }
        
        static func buildButton(_ imageName: String) -> UIButton {
            let image = UIImage(imageLiteralResourceName: imageName)
            let button = UIButton(type: .custom)
            button.setImage(image, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: 50),
                button.heightAnchor.constraint(equalToConstant: 50)
            ])
            return button
        }
        
        static func buildStackView() -> UIStackView {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 10.0
            stackView.alignment = .fill
            stackView.distribution = .fill
            stackView.translatesAutoresizingMaskIntoConstraints = false
            return stackView
        }
    }
}
