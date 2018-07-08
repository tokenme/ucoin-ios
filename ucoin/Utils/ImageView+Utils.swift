//
//  ImageView+Utils.swift
//  ucoin
//
//  Created by Syd on 2018/7/3.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit
import SnapKit
import moa

extension UIImageView {
    
    func download(url: String, complete: ((_ imageVIew: UIView, _ image: MoaImage) -> Void)?) -> Void {
        self.moa.onSuccess = {[weak self] image in
            guard let weakSelf = self else {
                return image
            }
            complete?(weakSelf, image)
            return image
        }
        self.moa.url = url
    }
    
}
