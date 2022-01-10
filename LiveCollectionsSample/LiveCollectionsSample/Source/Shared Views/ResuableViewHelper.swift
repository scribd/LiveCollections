//
//  ResuableViewHelper.swift
//  LiveCollectionsSample
//
//  Created by Paris Pinkney on 7/7/16.
//  Copyright © 2016 Scribd. All rights reserved.
//

import UIKit

extension UITableViewCell {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UICollectionReusableView {
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}
