//
//  AnnotationBottomControlView.swift
//  KeypointAnnotation
//
//  Created by doyoung-gwak on 2020/02/29.
//  Copyright © 2020 tucan9389. All rights reserved.
//

import UIKit

protocol AnnotationBottomControlViewDelegate {
    func select(indexRate: CGFloat)
    func nextImage()
    func previousImage()
}

class AnnotationBottomControlView: UIView {
    
    var delegate: (AnnotationBottomControlViewDelegate & SaveDelegate)? = nil
    
    let leftButton: UIButton = UIButton()
    let rightButton: UIButton = UIButton()
    let bottomTimeLabel: UILabel = UILabel()
    let thumbnailBGView: UIView = UIView()
    var thumbnailImages: [UIImageView] = []
    
    // var imageURLs: [URL] = []
    var images: [ImageAnnotation] = []
    var imagesURL: URL? = nil
    
    init() {
        super.init(frame: .zero)
        setInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setInit()
    }
    
    func setInit() {
        thumbnailBGView.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 0.5)
        leftButton.setTitle("<", for: .normal)
        rightButton.setTitle(">", for: .normal)
        leftButton.setTitleColor(UIColor.blue, for: .normal)
        rightButton.setTitleColor(UIColor.blue, for: .normal)
        leftButton.backgroundColor = UIColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 0.5)
        rightButton.backgroundColor = UIColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 0.5)
        bottomTimeLabel.font = UIFont.systemFont(ofSize: 10)
        bottomTimeLabel.adjustsFontSizeToFitWidth = true
        bottomTimeLabel.textColor = UIColor.black
        bottomTimeLabel.textAlignment = .center
        bottomTimeLabel.text = "TEST / TEST"
        
        self.addSubview(leftButton)
        self.addSubview(rightButton)
        self.addSubview(bottomTimeLabel)
        self.addSubview(thumbnailBGView)
        
        
        
        leftButton.addTarget(self.delegate, action: #selector(AnnotationViewController.previousImage), for: .touchUpInside)
        rightButton.addTarget(self.delegate, action: #selector(AnnotationViewController.nextImage), for: .touchUpInside)
    }
    
    override var frame: CGRect {
        didSet {
            // left, right button
            let buttonW: CGFloat = self.frame.height
            let buttonH: CGFloat = self.frame.height
            leftButton.frame = CGRect(x: 0, y: 0, width: buttonW, height: buttonH)
            rightButton.frame = CGRect(x: self.frame.width - buttonH, y: 0, width: buttonW, height: buttonH)
            
            // middle
            let thumbnailImageViewHeight: CGFloat = 44
            let thumbnailBGViewX: CGFloat = leftButton.frame.origin.x +  leftButton.frame.width
            let thumbnailBGViewW: CGFloat = rightButton.frame.origin.x - thumbnailBGViewX
            thumbnailBGView.frame = CGRect(x: thumbnailBGViewX, y: 0, width: thumbnailBGViewW, height: thumbnailImageViewHeight)
            
            // duration label
            let bottomH: CGFloat = self.frame.height - thumbnailImageViewHeight
            bottomTimeLabel.frame = CGRect(x: 0, y: self.frame.height - bottomH, width: self.frame.width, height: bottomH)
        }
    }
    
    func reloadThumbnails() {
        let totalW: CGFloat = thumbnailBGView.frame.width
        let totalH: CGFloat = thumbnailBGView.frame.height
        
        let imageH: CGFloat = totalH
        let imageW: CGFloat = imageH / 1.5
        
        let imageCount: Int = Int(floor(Double(totalW / imageW)))
        // if imageCount < generatedImageURLs.count { imageCount = generatedImageURLs.count }
        
        thumbnailBGView.subviews.forEach { $0.removeFromSuperview() }
        thumbnailImages = (0..<imageCount).map { i in
            let imageView = UIImageView()
            let ir: Float = Float(i) / Float(imageCount)
            var urlIndex: Int = Int(Float(self.images.count) * ir)
            if urlIndex >= self.images.count { urlIndex = self.images.count-1 }
            if let imageURL: URL = self.imagesURL?.appendingPathComponent(self.images[urlIndex].file_name) {
                let image = UIImage(contentsOfFile: imageURL.path)
                imageView.image = image
            }
            imageView.frame = CGRect(x: CGFloat(i)*imageW, y: 0, width: imageW, height: imageH)
            imageView.backgroundColor = UIColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 0.4)
            self.thumbnailBGView.addSubview(imageView)
            return imageView
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first, thumbnailImages.count > 0 {
            let p = touch.location(in: thumbnailBGView)
            var indexRate = p.x / self.thumbnailBGView.frame.width
            if indexRate < 0 { indexRate = 0.0 }
            else if indexRate > 1.0 { indexRate = 1.0 }
            
            delegate?.select(indexRate: indexRate)
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.save()
    }
}
