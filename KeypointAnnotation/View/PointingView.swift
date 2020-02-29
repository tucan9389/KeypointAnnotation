//
//  PointingView.swift
//  KeypointAnnotation
//
//  Created by doyoung-gwak on 2020/02/29.
//  Copyright © 2020 tucan9389. All rights reserved.
//

import UIKit

protocol PointingViewDelegate {
    func touchPoint(sender: PointingView, labelNumber: Int?)
}

class PointingView: UIView {
    
    var delegate: PointingViewDelegate? = nil
    
    private let middelDotView: UIView = UIView()
    private let label: UILabel = UILabel()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setInit()
    }
    
    func setInit() {
        self.isUserInteractionEnabled = true
        
        let pointW: CGFloat = 40
        frame = CGRect(x: 0, y: 0, width: pointW, height: pointW)
        clipsToBounds = true
        layer.cornerRadius = frame.width/2
        
        let dotW: CGFloat = 3
        middelDotView.frame = CGRect(x: 0, y: 0, width: dotW, height: dotW)
        middelDotView.clipsToBounds = true
        self.addSubview(middelDotView)
        middelDotView.center = CGPoint(x: frame.width/2, y: frame.height/2)
        
        label.frame = CGRect(x: 0, y: 2, width: frame.width, height: 7)
        label.text = "0"
        label.textAlignment = .center
        addSubview(label)
        
        let gesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(touchPoint(_:)))
        addGestureRecognizer(gesture)
    }
    
    var isActivate: Bool = false
    
    func setStyle(isActivate: Bool, color: UIColor) {
        
        middelDotView.backgroundColor = color
        
        if isActivate {
            let activeColor: UIColor = UIColor(red: 81.0/255.0, green: 207.0/255.0, blue: 102.0/255.0, alpha: 0.14)//UIColor(hexString: "#51cf66")
            
            backgroundColor = activeColor//UIColor(displayP3Red: 1.0, green: 0.0, blue: 0.0, alpha: 0.14)
            layer.borderColor = color.cgColor
            layer.borderWidth = 2
            
            let dotW: CGFloat = 3
            middelDotView.frame = CGRect(x: 0, y: 0, width: dotW, height: dotW)
            middelDotView.layer.cornerRadius = middelDotView.frame.width/2
            middelDotView.center = CGPoint(x: frame.width/2, y: frame.height/2)
            middelDotView.backgroundColor = color
            
            label.font = UIFont.systemFont(ofSize: 7, weight: .heavy)
            label.textColor = UIColor.white
            
        } else {
            
            backgroundColor = .clear
            // layer.borderColor = UIColor(hexString: "#3498db").cgColor
            layer.borderWidth = 0
            
            let dotW: CGFloat = 5
            middelDotView.frame = CGRect(x: 0, y: 0, width: dotW, height: dotW)
            middelDotView.layer.cornerRadius = middelDotView.frame.width/2
            middelDotView.center = CGPoint(x: frame.width/2, y: frame.height/2)
            middelDotView.backgroundColor = color
            
            label.font = UIFont.systemFont(ofSize: 7, weight: .heavy)
            label.textColor = .clear//UIColor.white
            
        }
        
        self.isActivate = isActivate
    }
    
    @objc func touchPoint(_ sender: UITapGestureRecognizer) {
        // change label
        //
        if let labelText = label.text,
            var labelNumber: Int = Int(labelText) {
            
            labelNumber += 1
            labelNumber %= 3
            
            delegate?.touchPoint(sender: self, labelNumber: labelNumber)
        } else {
            delegate?.touchPoint(sender: self, labelNumber: nil)
        }
    }
    
    func setLabelNumber(labelNumber: Int) {
        label.text = "\(labelNumber)"
    }
}
