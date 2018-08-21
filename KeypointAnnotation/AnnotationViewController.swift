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
    @IBOutlet weak var bottomControlView: BottomControlView!
    
    var videoInfo: VideoModel? = nil
    var annotationInfo: Annotation? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // title
        self.title = videoInfo?.filename ?? "N/A"
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(export))
        
        // bottom control
        bottomControlView.backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 0.2)
        bottomControlView.delegate = self
        
        // category view
        self.categoryView.delegate = self
        
        // image view
        self.mainImageView.delegate = self
        
            
        print(videoInfo?.url ?? "N/A")
        readAnnotation() { success in
            DispatchQueue.main.async {
                let categoryAnnotation: Annotation.CategoryAnnotation = Annotation.CategoryAnnotation()
                self.annotationInfo?.categories = [
                    categoryAnnotation
                ]
                
                let blue   = UIColor(hexString: "#3498db")
                let red    = UIColor(hexString: "#e74c3c")
                let yellow = UIColor(hexString: "#f1c40f")
                
                let gradient = DynamicGradient(colors: [blue, red, yellow])
                
                let colors = gradient.colorPalette(amount: UInt(categoryAnnotation.keypoints.count), inColorSpace: .hsl)
                
                self.categoryView.setUpButtons(category: categoryAnnotation, colors: colors)
                
                self.mainImageView.categoryColors = colors
                self.mainImageView.categoryAnnotation = categoryAnnotation
                
                self.bottomControlView.imagesURL = self.videoInfo?.imagesURL
                self.bottomControlView.images = self.annotationInfo?.images ?? []
                self.bottomControlView.reloadThumbnails()
                
                self.set(index: 0)
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.bottomControlView.frame = self.bottomControlView.frame
    }
    
    func readAnnotation(completion: @escaping (Bool)->()) {
        if let info = videoInfo {
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
        if let info = videoInfo {
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
    
    var index: Int = 0
    func set(index: Int) {
        self.index = index
        
        if  let annotationInfo = annotationInfo,
            let imageURL = videoInfo?.imagesURL.appendingPathComponent(annotationInfo.images[index].file_name) {
            let imageInfo: Annotation.ImageAnnotation = annotationInfo.images[index]
            
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
    
    @objc func export() {
        print("export!")
        if let info = videoInfo {
            let vc = UIActivityViewController(activityItems: [info.annotationJSONURL], applicationActivities: [])
            present(vc, animated: true, completion: nil)
        }
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





class Annotation: Decodable, Encodable {
    class ImageAnnotation: Decodable, Encodable {
        let file_name: String
        let width: Int
        let height: Int
        let id: Int
    }
    class KeypointAnnotation: Decodable, Encodable {
        var num_keypoints: Int // 11,
        let area: Int // 372410,
        var keypoints: [Int] /*": [
        290, 117, 2,
        281, 293, 2,
        393, 343, 2,
        170, 319, 2,
        342, 452, 2,
        130, 519, 2,
        256, 315, 2,
        197, 610, 2,
        303, 684, 2,
        146, 656, 2,
        152, 748, 2,
        215, 685, 1,
        0, 0, 0,
        0, 0, 0],*/
        let bbox: [Int] //[1, 85, 446, 835],
        var image_id: Int // 1,
        let category_id: Int // 1,
        var id: Int // 1
        
        init() {
            num_keypoints = 0
            area = 500000
            keypoints = Array<Int>(repeating: 0, count: 14*3)
            bbox = [0,0,0,0]
            image_id = -1
            category_id = 1
            id = -1
        }
    }
    class CategoryAnnotation: Decodable, Encodable {
        /*
          [{
         "supercategory": "human",
         "skeleton": [[1, 2], [2, 3], [2, 4], [3, 5], [5, 7], [4, 6], [6, 8], [2, 9], [2, 10], [9, 11], [10, 12], [11, 13], [12, 14]],
         "id": 1,
         "keypoints": ["top_head", "neck", "left_shoulder", "right_shoulder", "left_elbow", "right_elbow", "left_wrist", "right_wrist", "left_hip", "right_hip", "left_knee", "right_knee", "left_ankle", "right_ankle"],
         "name": "human"
         }]
         */
        let supercategory: String //hand,
        let skeleton: [[Int]]//[],
        let id: Int//": 1,
        let keypoints: [String]/*": [
        "ft",
        "jnt",
        "tjnt"
        ],*/
        let name: String//": "fingertip"
        init() {
            supercategory = "bust"
            name = "body"
            id = 1
//            keypoints = ["index", "index DIP", "index PIP", "index MP"/*, "middle", "ring", "baby", "thumb"*/]
            keypoints = ["head", "nose", "Rshoulder", "Lshoulder"]
            skeleton = [[1,2], [2,3], [2,4]]
        }
    }
    
    var images: [ImageAnnotation]
    var annotations: [KeypointAnnotation]
    var categories: [CategoryAnnotation]?
    
    func sort() {
        images.sort { (i1, i2) -> Bool in
            return i1.file_name < i2.file_name
        }
        annotations.sort { (k1, k2) -> Bool in
            return k1.id < k2.id
        }
    }
    
    func keypointAnnotation(of id: Int) -> KeypointAnnotation {
        for kp in annotations {
            if kp.id == id { return kp }
        }
        let kp: KeypointAnnotation = KeypointAnnotation()
        kp.id = id
        kp.image_id = id
        annotations.append(kp)
        return kp
    }
    
    func updateNumKeypoints() {
        for anno in annotations {
            anno.num_keypoints = 0
            for i in stride(from: 0, to: anno.keypoints.count, by: 3) {
                if anno.keypoints[i] == 2 {
                    anno.num_keypoints += 1
                }
            }
        }
    }
}



extension AnnotationViewController: BottomControlViewDelegate {
    @objc func select(indexRate: CGFloat) {
        if let annotationInfo = self.annotationInfo {
            let index = Int(indexRate*CGFloat(annotationInfo.images.count-1))
            self.set(index: index)
        }
    }
    @objc func nextImage() {
        guard let annotationInfo = self.annotationInfo else { return; }
        if self.index < annotationInfo.images.count-1 {
            self.set(index: self.index + 1)
            save()
        }
    }
    @objc func previousImage() {
        guard let _ = self.annotationInfo else { return; }
        if self.index > 0 {
            self.set(index: self.index - 1)
            save()
        }
    }
}

protocol BottomControlViewDelegate {
    func select(indexRate: CGFloat)
    func nextImage()
    func previousImage()
}

class BottomControlView: UIView {
    
    var delegate: (BottomControlViewDelegate & SaveDelegate)? = nil
    
    let leftButton: UIButton = UIButton()
    let rightButton: UIButton = UIButton()
    let bottomTimeLabel: UILabel = UILabel()
    let thumbnailBGView: UIView = UIView()
    var thumbnailImages: [UIImageView] = []
    
    // var imageURLs: [URL] = []
    var images: [Annotation.ImageAnnotation] = []
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

protocol AnnotationCategoryViewDelegate {
    func changed(categoryIndex: Int)
}
class AnnotationCategoryView: UIView {
    
    var categoryButtons: [UIButton] = []
    var delegate: (AnnotationCategoryViewDelegate & SaveDelegate)?
    var currentIndex: Int = 0
    
    func setUpButtons(category: Annotation.CategoryAnnotation, colors: [UIColor]) {
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

protocol SaveDelegate {
    func save()
}

protocol PointingViewDelegate {
    func touchPoint(sender: AnnotationImageView.PointingView, labelNumber: Int?)
}

class AnnotationImageView: UIImageView {
    
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
    
    var keypointAnnotation: Annotation.KeypointAnnotation?
    
    var categoryColors: [UIColor] = []
    var categoryAnnotation: Annotation.CategoryAnnotation? {
        didSet {
            if let categoryAnnotation = self.categoryAnnotation {
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
    
    func setAnnotation(keypointAnnotation: Annotation.KeypointAnnotation, index: Int) {
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
        let p = pointingViews[index].center
        var xr: CGFloat = p.x/self.frame.width
        var yr: CGFloat = p.y/self.frame.height
        if xr < 0 { xr = 0 }
        else if xr > 1 { xr = 1 }
        if yr < 0 { yr = 0 }
        else if yr > 1 { yr = 1 }
        
        if let image = self.image, let keypointAnnotation = self.keypointAnnotation {
            let x = xr * image.size.width
            let y = yr * image.size.height
            
            keypointAnnotation.keypoints[index*3 + 0] = Int(x)
            keypointAnnotation.keypoints[index*3 + 1] = Int(y)
            
            save()
        }
    }
}

extension AnnotationImageView: PointingViewDelegate {
    func touchPoint(sender: AnnotationImageView.PointingView, labelNumber: Int?) {
        if let labelNumber: Int = labelNumber {
            changeLabelNumber(number: labelNumber)
        }
        
        save()
    }
}
