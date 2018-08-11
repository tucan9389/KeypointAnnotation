//
//  ViewController.swift
//  KeypointAnnotation
//
//  Created by GwakDoyoung on 12/08/2018.
//  Copyright © 2018 tucan9389. All rights reserved.
//

import UIKit
import Alamofire
import ZIPFoundation
import Toast_Swift

class MainViewController: UIViewController {
    
    @IBOutlet weak var mainTableView: UITableView!
    
    var data: [VideoModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(export))
        
        self.view.makeToastActivity(.center)
        MyFileManager.shared.loadAndUnzip() {
            DispatchQueue.main.async {
                self.reloadIMGs()
                self.loadImageAndAnnotationCount()
                self.view.hideToastActivity()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadImageAndAnnotationCount()
    }
    
    func reloadIMGs() {
        let annotatedURLs: [URL]? = MyFileManager.shared.filenames(of: MyFileManager.shared.annotatedPath)
        if let urls: [URL] = annotatedURLs {
            self.data = urls.map { url in
                return VideoModel(url: url)
            }
        }
        self.mainTableView.reloadData()
    }
    
    func loadImageAndAnnotationCount() {
        let queue: DispatchQueue = DispatchQueue(label: "com.tucan.annotationloading")
        queue.async {
            
            var totalAnnotatedCount: Int = 0
            var totalImageCount: Int = 0
            let decoder = JSONDecoder()
            for info in self.data {
                let jsonURL: URL = info.annotationJSONURL
                do {
                    if let data = MyFileManager.shared.read(from: jsonURL) {
                        let annotation: Annotation = try decoder.decode(Annotation.self, from: data as Data)
                        info.annotatedImageCount = annotation.annotations.count
                        totalImageCount += annotation.images.count
                        totalAnnotatedCount += annotation.annotations.count
                    }
                } catch let e {
                    print("?? \(e)")
                }
            }
            
            DispatchQueue.main.async {
                self.mainTableView.reloadData()
                self.title = "\(totalAnnotatedCount) / \(totalImageCount)"
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "gotoAnnotationViewController",
            let annotationViewController = segue.destination as? AnnotationViewController,
            let indexPath = self.mainTableView.indexPathForSelectedRow {
            
            annotationViewController.videoInfo = data[indexPath.row]
        }
    }
    
    @objc func export() {
        print("export!!")
        self.view.makeToastActivity(.center)
        DispatchQueue(label: "com.tucan9389.export").async {
            MyFileManager.shared.zipAnnotatedDirectory { (zippedURL, success) in
                DispatchQueue.main.async {
                    self.view.hideToastActivity()
                    print("export end")
                    print("export \(success)")
                    if let zippedURL = zippedURL {
                        print("zipped url: \(zippedURL)")
                        let vc = UIActivityViewController(activityItems: [zippedURL], applicationActivities: [])
                        self.present(vc, animated: true, completion: nil)
                    } else {
                        print("no url....😥")
                    }
                }
            }
        }
        
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "AnnotationCell", for: indexPath)
        if let annotationCell: AnnotationCell = cell as? AnnotationCell {
            annotationCell.set(videoInfo: data[indexPath.row])
        }
        return cell
    }
}

extension MainViewController: UITableViewDelegate {
    
}

class AnnotationCell: UITableViewCell {
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    
    func set(videoInfo: VideoModel) {
        self.mainImageView.backgroundColor = UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 0.5)
        self.mainImageView.image = videoInfo.firstImage
        // self.mainImageView.clipsToBounds = true
        self.mainImageView.contentMode = .scaleAspectFit
        self.label1.text = videoInfo.filename
        self.label2.text = "\(String(format: "%04d", videoInfo.annotatedImageCount)) / \(String(format: "%04d", videoInfo.imageCount))"
        let rate: Double = Double(videoInfo.annotatedImageCount) / Double(videoInfo.imageCount)
        if rate == 1.0 {
            let color = UIColor(hexString: "#24E064")
            self.label2.textColor = UIColor(red: color.redComponent, green: color.greenComponent, blue: color.blueComponent, alpha: 0.9)
        } else if rate > 0.8 {
            let color = UIColor(hexString: "#3498db")
            self.label2.textColor = UIColor(red: color.redComponent, green: color.greenComponent, blue: color.blueComponent, alpha: 0.9)
        } else {
            let color = UIColor(hexString: "#f1c40f")
            self.label2.textColor = UIColor(red: color.redComponent, green: color.greenComponent, blue: color.blueComponent, alpha: 0.9)
        }
    }
}

class VideoModel {
    let url: URL
    var filename: String {
        return url.lastPathComponent
    }
    var _imageURLs: [URL]? = nil
    var imageURLs: [URL]? {
        if let urls = _imageURLs {
            return urls
        } else {
            let imagesURL = MyFileManager.shared.imagesPath(from: url)
            _imageURLs = MyFileManager.shared.filenames(of: imagesURL)
            return _imageURLs
        }
    }
    var imageCount: Int {
        return imageURLs?.count ?? 0
    }
    var annotatedImageCount: Int = 0
    var annotationJSONURL: URL {
        return url.appendingPathComponent("annotation.json")
    }
    var imagesURL: URL {
        return url.appendingPathComponent("images")
    }
    var _firstImage: UIImage? = nil
    var firstImage: UIImage? {
        if let image = _firstImage {
            return image
        } else {
            if let imageURL = self.imageURLs?.first {
                _firstImage = UIImage(contentsOfFile: imageURL.path)
                return _firstImage
            } else {
                return nil
            }
        }
    }
    
    init(url: URL) {
        self.url = url
    }
}
