//
//  ImageFileEncoder.swift
//  LiveCollectionsSample
//
//  Created by Stephane Magne on 7/15/18.
//  Copyright © 2018 Scribd. All rights reserved.
//

import UIKit

final class ImageFileEncoder: FileEncoderInterface {
    
    let folderName: String
    
    init(folderName: String) {
        self.folderName = folderName
    }

    func decode(from data: Data) -> UIImage? {
        return UIImage(data: data)
    }
    
    func encode(for image: UIImage) -> Data? {
        return image.pngData()
    }
}
