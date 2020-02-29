//
//  MyFileManager.swift
//  FingertipAnnotationMaker
//
//  Created by GwakDoyoung on 16/07/2018.
//  Copyright © 2018 tucan9389. All rights reserved.
//

import UIKit
import Alamofire
import ZIPFoundation

/*
 ├ Original_Video (Not support yet)
    ├ IMG_9381.MOV
    ├ IMG_8381.MOV
 ├ Original_Image (Not support yet)
    ├ IMG_9383.HEIV
    ├ IMG_8382.HEIV
 ├ Annotated
    ├ IMG_9381
        ├ annotation.json
        ├ images
            ├ IMG_9381_00001.jpeg
            ├ IMG_9381_00002.jpeg
            ├ IMG_9381_00003.jpeg
            ├ IMG_9381_00004.jpeg
    ├ IMG_8381
        ├ annotation.json
        ├ images
            ├ IMG_8381_00001.jpeg
            ├ IMG_8381_00002.jpeg
            ├ IMG_8381_00003.jpeg
            ├ IMG_8381_00004.jpeg
 
 */

// sample dataset: https://drive.google.com/file/d/1AZlU17IvU2MQ7wLvKx8eDKaw7CSU9jPI

class MyFileManager {
    static let shared: MyFileManager = MyFileManager()
    private let filemanager: FileManager = FileManager.default
    
    private let annotatedDirectory = "Annotated"
    
    private let annotatedJSONFilename = "annotation"
    private let annotatedImageDirectory = "images"
    
    let documentsURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    public var annotatedPath: URL {
        let url = documentsURL.appendingPathComponent(annotatedDirectory)
        return url//createAndGetDirectoryPath(with: url)
    }
    
    func imagesPath(from annotatedURL: URL) -> URL {
        return createAndGetDirectoryPath(with: annotatedURL.appendingPathComponent(annotatedImageDirectory))
    }
    
    func createAndGetDirectoryPath(with url: URL) -> URL {
        if !filemanager.fileExists(atPath: url.path) {
            do {
                try filemanager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                
            }
        }
        return url
    }
    
    func loadAndUnzip(completion: @escaping ()->()) {
        if let filePath = Bundle.main.path(forResource: "Annotated", ofType: "zip"),
            let url: URL = URL(string: "file://\(filePath)") {
            unzip(sourceURL: url) {
                completion()
            }
        } else {
            completion()
        }
    }
    
    func unzip(sourceURL: URL, completion: @escaping ()->()) {
        let destinationURL = self.documentsURL
        guard !filemanager.fileExists(atPath: annotatedPath.path) else {
            print("👍👍👍already unzipped!!")
            completion()
            return;
        }
        print(sourceURL)
        print(destinationURL)
        do {
            try self.filemanager.unzipItem(at: sourceURL, to: destinationURL)
            
            print("Annotated Path:")
            print(self.filenames(of: self.annotatedPath) ?? "---")
            completion()
        } catch {
            print("Extraction of ZIP archive failed with error:\(error)")
            completion()
        }
    }
    
    func downloadAndUnzip(urlPath: String, completion: @escaping ()->()) {
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            documentsURL.appendPathComponent("dataset.zip")
            return (documentsURL, [.removePreviousFile])
        }
        
        if let url: URL = URL(string: urlPath) {
            Alamofire.download(url, to: destination).downloadProgress(closure: { (progress) in
                //progress closure
            }).responseData { response in
                if let destinationUrl = response.destinationURL {
                    print("destinationUrl \n\(destinationUrl.absoluteURL)")
                    
                    let sourceURL = self.documentsURL.appendingPathComponent("dataset.zip")
                    self.unzip(sourceURL: sourceURL, completion: completion)
                } else {
                    completion()
                }
            }
        }
    }
    
    func zipAnnotatedDirectory(completion: @escaping (URL?, Bool)->()) {
        let dateformatter: DateFormatter = DateFormatter()
        dateformatter.dateFormat = "YYYYMMDDHHmmss"
        let dateString: String = dateformatter.string(from: Date())
        
        let sourceURL: URL = annotatedPath
        let destinationURL: URL = self.documentsURL.appendingPathComponent("annotated-dataset-\(dateString).zip")
        
        print("source url : \(sourceURL)")
        print("destin url : \(destinationURL)")
        
        print("start zip🤫")
        
        do {
            try self.filemanager.zipItem(at: sourceURL, to: destinationURL)
            
            print("Annotated Path:")
            print(self.filenames(of: self.documentsURL) ?? "---")
            completion(destinationURL, true)
        } catch {
            print("Zip failed with error:\(error)")
            completion(nil, false)
        }
    }
    
    
    public func filenames(of url: URL) -> [URL]? {
        do {
            let fileURLs: [URL] = try filemanager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            let urlStrings = fileURLs.map({ $0.path }).sorted()
            let urls = urlStrings.map({ URL(string: $0) })
            return urls.compactMap({ $0 })
        } catch {
            return nil
        }
    }
    
    public func read(from localUrl: URL) -> Data? {
        if filemanager.fileExists(atPath: localUrl.path){
            if let data = NSData(contentsOfFile: localUrl.path) {
                return data as Data
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    public func write(to localUrl: URL, with data: Data) {
        filemanager.createFile(atPath: localUrl.path, contents: data, attributes: nil)
    }
}

extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    var subDirectories: [URL] {
        guard isDirectory else { return [] }
        return (try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter{ $0.isDirectory }) ?? []
    }
}
