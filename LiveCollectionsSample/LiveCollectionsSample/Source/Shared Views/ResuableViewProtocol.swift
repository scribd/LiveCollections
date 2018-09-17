//
//  ResuableViewProtocol.swift
//  LiveCollectionsSample
//
//  Created by Paris Pinkney on 7/7/16.
//  Copyright © 2016 Scribd. All rights reserved.
//

import UIKit

protocol ReusableViewProtocol: class {
    static var reuseIdentifier: String { get }
}

extension UITableViewCell: ReusableViewProtocol {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UICollectionReusableView: ReusableViewProtocol {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
