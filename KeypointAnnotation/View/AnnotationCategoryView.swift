//
//  AnnotationCategoryView.swift
//  KeypointAnnotation
//
//  Created by doyoung-gwak on 2020/02/29.
//  Copyright © 2020 tucan9389. All rights reserved.
//

import UIKit

protocol AnnotationCategoryViewDelegate {
    func changed(categoryIndex: Int)
}
class AnnotationCategoryView: UIView {
    
    var categoryButtons: [UIButton] = []
    var delegate: (AnnotationCategoryViewDelegate & SaveDelegate)?
    var currentIndex: Int = 0
    
    func setUpButtons(category: CategoryAnnotation, colors: [UIColor]) {
        var categoryButtons: [UIButton] = []
        for (color, title) in zip(colors, category.keypoints) {
            let button = getButton(with: title, with: color)
            button.tag = colors.index(of: color) ?? 0
            button.addTarget(self, action: #selector(touchButton(_:)), for: .touchUpInside)
            categoryButtons.append(button)
        }
        self.categoryButtons = categoryButtons
        
        categoryButtons.first?.alpha = 0.25
    }
    
    @objc func touchButton(_ sender: UIButton) {
        categoryButtons.forEach({$0.alpha = 1})
        sender.alpha = 0.5
        self.currentIndex = sender.tag
        self.delegate?.changed(categoryIndex: sender.tag)
    }
    
    func getButton(with text: String, with color: UIColor) -> UIButton {
        let button: UIButton = UIButton()
        button.backgroundColor = color
        button.setTitle(text, for: .normal)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        button.setTitleColor(UIColor.white, for: .normal)
        self.addSubview(button)
        return button
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print("layoutSubviews in category view: \(self.frame)")
        let size: CGSize = self.frame.size
        
        guard !categoryButtons.isEmpty else { return; }
        
        let buttonW: CGFloat = size.width / CGFloat(categoryButtons.count)
        for i in 0..<categoryButtons.count {
            let button: UIButton = categoryButtons[i]
            button.frame = CGRect(x: CGFloat(i) * buttonW, y: 0, width: buttonW, height: size.height)
        }
    }
}
