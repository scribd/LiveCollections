//
//  PresentationView.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/15/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

final class PresentationView: UIView {

    let containerView = UIView()
    let thinLine = UIView()
    let playerControl = PlayerControl()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setUpSubviews() {
        backgroundColor = .white
        
        addSubview(containerView)
        addSubview(thinLine)
        addSubview(playerControl)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        thinLine.translatesAutoresizingMaskIntoConstraints = false
        playerControl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),

            thinLine.topAnchor.constraint(equalTo: containerView.bottomAnchor),
            thinLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            thinLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            thinLine.heightAnchor.constraint(equalToConstant: 1),

            playerControl.topAnchor.constraint(equalTo: thinLine.bottomAnchor, constant: 10),
            playerControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            playerControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
        ])
        
        thinLine.backgroundColor = .gray
    }
    
    func addViewToPresent(_ view: UIView) {
        view.backgroundColor = .white
        containerView.subviews.forEach { $0.removeFromSuperview() }
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: containerView.topAnchor),
            view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
}
