//
//  Photo+extension.swift
//  FingertipAnnotationMaker
//
//  Created by GwakDoyoung on 16/07/2018.
//  Copyright © 2018 tucan9389. All rights reserved.
//

import Photos
import AVFoundation

extension PHAsset {
    var originalFilename: String? {
        return PHAssetResource.assetResources(for: self).first?.originalFilename
    }
}

extension AVAsset {
    var thumbnail: UIImage? {
        return image(at: CMTime(seconds: 1, preferredTimescale: 1), from: AVAssetImageGenerator(asset: self))
    }
    
    func image(at time: CMTime, from imageGenerator: AVAssetImageGenerator) -> UIImage? {        
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print(error)
            return nil
        }
    }
}
