//
//  UIViewController+extension.swift
//  FingertipAnnotationMaker
//
//  Created by GwakDoyoung on 16/07/2018.
//  Copyright © 2018 tucan9389. All rights reserved.
//

import UIKit

extension UIViewController {
    func showAlert(msg: String = "alert!") {
        let alert = UIAlertController(title: "alert", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension UIButton {
    private func actionHandleBlock(action:((UIButton) -> Void)? = nil) {
        struct __ {
            static var action :((UIButton) -> Void)?
        }
        if action != nil {
            __.action = action
        } else {
            __.action?(self)
        }
    }
    
    @objc private func triggerActionHandleBlock() {
        self.actionHandleBlock()
    }
    
    func actionHandle(controlEvents control :UIControlEvents, ForAction action:@escaping (UIButton) -> Void) {
        self.actionHandleBlock(action: action)
        self.addTarget(self, action: #selector(UIButton.triggerActionHandleBlock), for: control)
    }
}

extension UIView {
    func bringFront() {
        if let superview = self.superview {
            superview.bringSubview(toFront: self)
        }
    }
}

extension UIImage {
    func save(to path: URL, compressionQuality: CGFloat) -> Bool {
        guard let data = UIImageJPEGRepresentation(self, compressionQuality) ?? UIImagePNGRepresentation(self) else {
            return false
        }
        do {
            try data.write(to: path)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}
