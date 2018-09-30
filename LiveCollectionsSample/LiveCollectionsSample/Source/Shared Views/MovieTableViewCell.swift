//
//  MovieTableViewCell.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 9/3/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

final class MovieTableViewCell: UITableViewCell {

    static let cellHeight: CGFloat = 80
    private(set) var identifier: UInt = .max

    private let movieImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.25)
        imageView.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        imageView.layer.borderWidth = 0.5
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .darkGray
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _setUpSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func _setUpSubviews() {
        
        [movieImageView, titleLabel, descriptionLabel].forEach { view in
            contentView.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        let padding = Constants.padding
        let interItemPadding = Constants.interItemPadding
        
        NSLayoutConstraint.activate([
            movieImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding.top),
            movieImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding.bottom),
            movieImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding.left),
            movieImageView.widthAnchor.constraint(equalTo: movieImageView.heightAnchor, multiplier: 2/3),
            
            titleLabel.topAnchor.constraint(equalTo: movieImageView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: movieImageView.trailingAnchor, constant: interItemPadding),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding.right),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: movieImageView.bottomAnchor)
        ])
    }
    
    func update(with movie: Movie) {
        titleLabel.text = movie.title
        descriptionLabel.text = movie.overview
        identifier = movie.id
    }
    
    func update(with image: UIImage) {
        movieImageView.image = image
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        identifier = .max
        titleLabel.text = nil
        descriptionLabel.text = nil
        movieImageView.image = nil
    }
}

private extension MovieTableViewCell {
    enum Constants {
        static var padding: UIEdgeInsets {
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                return UIEdgeInsets(top: 5, left: 40, bottom: 5, right: 40)
            default:
                return UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
            }
        }

        static var interItemPadding: CGFloat {
            switch UIDevice.current.userInterfaceIdiom {
            case .pad:
                return 20
            default:
                return 10
            }
        }
    }
}
