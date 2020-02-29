//
//  AnnotationViewController.swift
//  Annotation
//
//  Created by GwakDoyoung on 19/07/2018.
//  Copyright © 2018 tucan9389. All rights reserved.
//

import UIKit
import DynamicColor

class AnnotationViewController: UIViewController {
    
    @IBOutlet weak var mainImageView: AnnotationImageView!
    @IBOutlet weak var categoryView: AnnotationCategoryView!
    @IBOutlet weak var bottomControlView: AnnotationBottomControlView!
    
    var imageAnnotationGroup: ImageAnnotationGroup? = nil
    var annotationInfo: Annotation? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // navigation bar
        self.title = imageAnnotationGroup?.filename ?? "N/A"
        let exportItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(export))
        let resetItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(reset))
        self.navigationItem.rightBarButtonItems = [resetItem, exportItem]
        
        // bottom control
        bottomControlView.backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 0.2)
        bottomControlView.delegate = self
        
        // category view
        self.categoryView.delegate = self
        
        // image view
        self.mainImageView.delegate = self
        
            
        print(imageAnnotationGroup?.url ?? "N/A")
        readAnnotation() { success in
            DispatchQueue.main.async {
//                let categoryAnnotation: Annotation.CategoryAnnotation = Annotation.CategoryAnnotation()
//                self.annotationInfo?.categories = [
//                    categoryAnnotation
//                ]
                guard let categoryAnnotation: CategoryAnnotation = self.annotationInfo?.categories?.first else {
                    fatalError("There is no 'categories' information on annotation.json")
                }
                
                let blue   = UIColor(hexString: "#3498db")
                let red    = UIColor(hexString: "#e74c3c")
                let yellow = UIColor(hexString: "#f1c40f")
                
                let gradient = DynamicGradient(colors: [blue, red, yellow])
                
                let colors = gradient.colorPalette(amount: UInt(categoryAnnotation.keypoints.count), inColorSpace: .hsl)
                
                self.categoryView.setUpButtons(category: categoryAnnotation, colors: colors)
                
                self.mainImageView.categoryColors = colors
                self.mainImageView.categoryAnnotation = categoryAnnotation
                
                self.bottomControlView.imagesURL = self.imageAnnotationGroup?.imagesURL
                self.bottomControlView.images = self.annotationInfo?.images ?? []
                self.bottomControlView.reloadThumbnails()
                
                self.index = 0
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.bottomControlView.frame = self.bottomControlView.frame
    }
    
    func readAnnotation(completion: @escaping (Bool)->()) {
        if let info = imageAnnotationGroup {
            let jsonURL: URL = info.annotationJSONURL
            let decoder = JSONDecoder()
            do {
                if let data = MyFileManager.shared.read(from: jsonURL) {
                    let annotation: Annotation = try decoder.decode(Annotation.self, from: data as Data)
                    annotation.sort()
                    self.annotationInfo = annotation
                    completion(true)
                } else {
                    completion(false)
                }
            } catch let e {
                print("?? \(e)")
                completion(false)
            }
        } else {
            completion(false)
        }
    }
    
    func writeAnnotation(completion: @escaping (Bool)->()) {
        if let info = imageAnnotationGroup {
            let jsonURL: URL = info.annotationJSONURL
            let encoder = JSONEncoder()
            do {
                let data = try encoder.encode(annotationInfo)
                MyFileManager.shared.write(to: jsonURL, with: data)
                completion(true)
            } catch let e {
                print("?? \(e)")
                completion(false)
            }
        } else {
            completion(false)
        }
    }
    
    var index: Int = 0 {
        didSet {
            if let annotationInfo = annotationInfo,
                let imageURL = imageAnnotationGroup?.imagesURL.appendingPathComponent(annotationInfo.images[index].file_name) {
                let imageInfo: ImageAnnotation = annotationInfo.images[index]
                
                print(imageInfo.file_name)
                
                let image = UIImage(contentsOfFile: imageURL.path)
                self.mainImageView.image = image
                
                let keypointAnnotation = annotationInfo.keypointAnnotation(of: imageInfo.id)
                self.mainImageView.setAnnotation(keypointAnnotation: keypointAnnotation,
                                                 index: categoryView.currentIndex)
                
                
                let bottomTitle = "\(index+1) / \(annotationInfo.images.count)"
                self.bottomControlView.bottomTimeLabel.text = bottomTitle
            }
        }
    }
    
    @objc func export() {
        print("export!")
        if let info = imageAnnotationGroup {
            let vc = UIActivityViewController(activityItems: [info.annotationJSONURL], applicationActivities: [])
            present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func reset() {
        print("reset!")
        
    }
}

extension AnnotationViewController: AnnotationCategoryViewDelegate {
    func changed(categoryIndex: Int) {
        print("categoryIndex: \(categoryIndex)")
        self.mainImageView.setAnnotationIndex(index: categoryIndex)
        save()
    }
}

extension AnnotationViewController: SaveDelegate {
    func save() {
        writeAnnotation { (success) in
            print("write", success)
        }
    }
}





extension AnnotationViewController: AnnotationBottomControlViewDelegate {
    @objc func select(indexRate: CGFloat) {
        if let annotationInfo = self.annotationInfo {
            let index = Int(indexRate*CGFloat(annotationInfo.images.count-1))
            self.index = index
        }
    }
    @objc func nextImage() {
        guard let annotationInfo = self.annotationInfo else { return; }
        if self.index < annotationInfo.images.count-1 {
            if mainImageView?.updateKeypoint() ?? false {
                save()
            }
            self.index = self.index + 1
        }
    }
    @objc func previousImage() {
        guard let _ = self.annotationInfo else { return; }
        if self.index > 0 {
            if mainImageView?.updateKeypoint() ?? false {
                save()
            }
            self.index = self.index - 1
        }
    }
}

protocol SaveDelegate {
    func save()
}
