//
//  Number+Utils.swift
//  ucoin
//
//  Created by Syd on 2018/6/19.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import Foundation

extension Double {
    func formate(formatter: NumberFormatter) -> String {
        if self >= 1e9 {
            let formatted = formatter.string(from: NSDecimalNumber(value: self / 1e9) )
            return "\(formatted!)亿"
        }else if self > 1e5 {
            let formatted = formatter.string(from: NSDecimalNumber(value: self / 1e5) )
            return "\(formatted!)万"
        }
        return formatter.string(from: NSDecimalNumber(value: self) )!
    }
}
