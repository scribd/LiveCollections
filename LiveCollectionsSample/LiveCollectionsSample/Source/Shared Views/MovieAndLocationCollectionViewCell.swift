//
//  MovieAndLocationCollectionViewCell.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 9/5/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

final class MovieAndLocationCollectionViewCell: UICollectionViewCell {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25)
        imageView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        imageView.layer.borderWidth = 0.5
        return imageView
    }()
    
    private let inTheatersBanner: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor.blue.withAlphaComponent(0.8)
        let fontSize: CGFloat = isIpad() ? 10 : 8
        label.font = .systemFont(ofSize: fontSize, weight: .bold)
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = "Now Playing!"
        label.isHidden = true
        return label
    }()
    
    private(set) var identifier: UInt = .max
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpSubviews() {
        addSubview(imageView)
        addSubview(inTheatersBanner)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        inTheatersBanner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            inTheatersBanner.leadingAnchor.constraint(equalTo: leadingAnchor),
            inTheatersBanner.trailingAnchor.constraint(equalTo: trailingAnchor),
            inTheatersBanner.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1/3),
            inTheatersBanner.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
    
    func update(with movieAndLocation: DistributedMovie) {
        identifier = movieAndLocation.movie.id
        inTheatersBanner.isHidden = movieAndLocation.isInTheaters == false
    }
    
    func update(with image: UIImage) {
        imageView.image = image
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        identifier = .max
    }
}
