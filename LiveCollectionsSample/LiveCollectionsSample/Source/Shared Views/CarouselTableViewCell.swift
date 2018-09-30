//
//  CarouselTableViewCell.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 8/19/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit
import LiveCollections

final class CarouselTableViewCell: UITableViewCell {
    
    static let cellHeight: CGFloat = 85
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 44, height: 66)
        layout.minimumLineSpacing = 20
        layout.sectionInset = UIEdgeInsets(top: 9, left: 20, bottom: 9, right: 20)
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        return collectionView
    }()

    private weak var viewProvider: CollectionViewProvider?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        _setUpSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func register(with provider: CollectionViewDataProvider) {
        provider.registerCollectionView(collectionView)
        viewProvider = provider.viewProvider
    }
    
    private func _setUpSubviews() {
        contentView.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }
}
