//
//  LinearActivityIndicatorView.swift
//  ucoin
//
//  Created by Syd on 2018/7/6.
//  Copyright © 2018年 ucoin.io. All rights reserved.
//

import UIKit

class LinearActivityIndicatorView: UIView {
    
    public var hidesWhenStopped = true
    
    private let duration = 1.5
    private let leftGradientLayer = CAGradientLayer()
    private let rightGradientLayer = CAGradientLayer()
    private let leftAnimation = CABasicAnimation(keyPath: "position.x")
    private let rightAnimation = CABasicAnimation(keyPath: "position.x")
    private var animating = false
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        clipsToBounds = true
        layer.cornerRadius = bounds.size.height * 0.5
        
        if (hidesWhenStopped) {
            isHidden = !animating
        }
        layer.addSublayer(leftGradientLayer)
        layer.addSublayer(rightGradientLayer)
    }
    
    public func startAnimating() {
        animating = true
        
        let color = tintColor.withAlphaComponent(0.7)
        let clear = tintColor.withAlphaComponent(0) // different from UIColor.clear for tintColor == .white in gradient!
        leftGradientLayer.colors = [clear.cgColor, color.cgColor]
        leftGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        leftGradientLayer.endPoint = CGPoint(x: 1, y: 0)
        leftGradientLayer.anchorPoint = CGPoint(x: 0, y: 0)
        leftGradientLayer.frame = CGRect(x: 0, y: 0, width: bounds.size.width, height: bounds.size.height)
        leftGradientLayer.cornerRadius = bounds.size.height * 0.5
        leftGradientLayer.masksToBounds = true
        
        leftAnimation.fromValue = -self.bounds.size.width
        leftAnimation.toValue = self.bounds.size.width
        leftAnimation.duration = duration
        leftAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        leftAnimation.repeatCount = Float.infinity
        leftAnimation.isRemovedOnCompletion = false // continue running after app was in background
        leftGradientLayer.add(leftAnimation, forKey: "leftAnimation")
        
        rightGradientLayer.colors = [clear.cgColor, color.cgColor]
        rightGradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        rightGradientLayer.endPoint = CGPoint(x: 0, y: 0)
        rightGradientLayer.anchorPoint = CGPoint(x: 0, y: 0)
        rightGradientLayer.frame = CGRect(x: bounds.size.width, y: 0, width: bounds.size.width, height: bounds.size.height)
        rightGradientLayer.cornerRadius = bounds.size.height * 0.5
        rightGradientLayer.masksToBounds = true
        
        rightAnimation.fromValue = self.bounds.size.width
        rightAnimation.toValue = -self.bounds.size.width
        rightAnimation.duration = duration
        rightAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        rightAnimation.timeOffset = 0.5 * duration
        rightAnimation.repeatCount = Float.infinity
        rightAnimation.isRemovedOnCompletion = false
        rightGradientLayer.add(rightAnimation, forKey: "rightAnimation")
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public func stopAnimating() {
        animating = false
        leftGradientLayer.removeAllAnimations()
        rightGradientLayer.removeAllAnimations()
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public var isAnimating: Bool {
        get {
            return animating
        }
    }
    
    override public func tintColorDidChange() {
        super.tintColorDidChange()
        if isAnimating {
            startAnimating()
        } else {
            startAnimating()
            stopAnimating()
        }
    }
}
