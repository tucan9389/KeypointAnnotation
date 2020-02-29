//
//  AnnotationImageView.swift
//  KeypointAnnotation
//
//  Created by doyoung-gwak on 2020/02/29.
//  Copyright © 2020 tucan9389. All rights reserved.
//

import UIKit

class AnnotationImageView: UIImageView {
    var keypointAnnotation: KeypointAnnotation?
    
    var categoryColors: [UIColor] = []
    var categoryAnnotation: CategoryAnnotation? {
        didSet {
            guard let categoryAnnotation = self.categoryAnnotation else { return }
            let count = categoryAnnotation.keypoints.count
            
            while pointingViews.count < count {
                let pointingView: PointingView = PointingView()
                self.addSubview(pointingView)
                pointingViews.append(pointingView)
            }
            
            while pointingViews.count > count {
                if let view = pointingViews.last {
                    view.removeFromSuperview()
                }
                pointingViews.removeLast()
            }
            
            for i in 0..<pointingViews.count {
                pointingViews[i].setStyle(isActivate: i == index,
                                          color: categoryColors[i])
            }
        }
    }
    var index: Int = 0
    
    // var pointingView: PointingView = PointingView()
    private var pointingViews: [PointingView] = []
    
    var delegate: SaveDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setInit()
    }
    
    func setInit() {
        self.isUserInteractionEnabled = true
    }
    
    func setAnnotation(keypointAnnotation: KeypointAnnotation, index: Int) {
        self.keypointAnnotation = keypointAnnotation
        self.setAnnotationIndex(index: index)
    }
    func setAnnotationIndex(index: Int) {
        self.index = index
        if let keypointAnnotation = self.keypointAnnotation, let image = self.image {
            for i in 0..<pointingViews.count {
                let pointingView: PointingView = pointingViews[i]
                
                let keypoint = [keypointAnnotation.keypoints[i*3],
                                keypointAnnotation.keypoints[i*3 + 1],
                                keypointAnnotation.keypoints[i*3 + 2]]
                let x = keypoint[0] == 0 && keypoint[1] == 0 ? image.size.width/2 : CGFloat(keypoint[0])
                let y = keypoint[0] == 0 && keypoint[1] == 0 ? image.size.height/2 : CGFloat(keypoint[1])
                pointingView.center = convert(from: CGPoint(x: x, y: y))
                
                let labelNumber: Int = keypoint[2]
                pointingView.setLabelNumber(labelNumber: labelNumber)
                
                pointingView.setStyle(isActivate: i==index,
                                      color: categoryColors[i])
            }
        }
    }
    
    func convert(from p: CGPoint) -> CGPoint {
        let xr = p.x / (self.image?.size.width  ?? 1.0)
        let yr = p.y / (self.image?.size.height ?? 1.0)
        let screenX = self.frame.width * xr
        let screenY = self.frame.height * yr
        return CGPoint(x: screenX, y: screenY)
    }
    
    //
    func save() {
        delegate?.save()
    }

    // event
    func changeLabelNumber(number: Int) {
        if let keypointAnnotation = self.keypointAnnotation {
            keypointAnnotation.keypoints[index*3 + 2] = number
            pointingViews[index].setLabelNumber(labelNumber: number)
        }
    }
    
    private var initialPoint: CGPoint = .zero
    private var initialViewPoint: CGPoint = .zero
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let p = touch.location(in: self)
            initialPoint = p
            initialViewPoint = pointingViews[index].center
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let p = touch.location(in: self)
            let vectorP = CGPoint(x: p.x - initialPoint.x, y: p.y - initialPoint.y)
            pointingViews[index].center = CGPoint(x: initialViewPoint.x + vectorP.x, y: initialViewPoint.y + vectorP.y)
            
            if CGRect(origin: .zero, size: self.frame.size).contains(pointingViews[index].center) {
                changeLabelNumber(number: 2)
            } else {
                changeLabelNumber(number: 1)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if updateKeypoint() == true {
            save()
        }
    }
    
    public func updateKeypoint() -> Bool {
        if let currentKeypoint = currentKeypoint(),
            let keypointAnnotation = self.keypointAnnotation {
            
            keypointAnnotation.keypoints[index*3 + 0] = Int(currentKeypoint.x)
            keypointAnnotation.keypoints[index*3 + 1] = Int(currentKeypoint.y)
            
            return true
        } else {
            return false
        }
    }
    
    func currentKeypoint() -> CGPoint? {
        let p = pointingViews[index].center
        var xr: CGFloat = p.x/self.frame.width
        var yr: CGFloat = p.y/self.frame.height
        if xr < 0 { xr = 0 }
        else if xr > 1 { xr = 1 }
        if yr < 0 { yr = 0 }
        else if yr > 1 { yr = 1 }
        
        if let image = self.image {
            let x = xr * image.size.width
            let y = yr * image.size.height
            
            return CGPoint(x: x, y: y)
        } else {
            return nil
        }
    }
}

extension AnnotationImageView: PointingViewDelegate {
    func touchPoint(sender: PointingView, labelNumber: Int?) {
        if let labelNumber: Int = labelNumber {
            changeLabelNumber(number: labelNumber)
        }
        
        save()
    }
}
