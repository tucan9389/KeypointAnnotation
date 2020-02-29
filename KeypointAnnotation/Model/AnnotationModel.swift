//
//  AnnotationModel.swift
//  KeypointAnnotation
//
//  Created by doyoung-gwak on 2020/02/29.
//  Copyright © 2020 tucan9389. All rights reserved.
//

import Foundation

class Annotation: Decodable, Encodable {
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
        let kp = makeKeypointAnnotation(with: id)
        annotations.append(kp)
        return kp
    }
    
    func makeKeypointAnnotation(with id: Int) -> KeypointAnnotation {
        let number_of_keypoints = categories?.first?.keypoints.count
        let kp: KeypointAnnotation = KeypointAnnotation(image_id: id, id: id, number_of_keypoints: number_of_keypoints)
        return kp
    }
    
    func resetKeypointAnnotation(of id: Int) {
        for index in 0..<annotations.count {
            if annotations[index].id == id {
                annotations[index] = makeKeypointAnnotation(with: id)
            }
        }
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

class ImageAnnotation: Decodable, Encodable {
    let file_name: String
    let width: Int
    let height: Int
    let id: Int
    
    init(file_name: String, width: Int, height: Int, id: Int) {
        self.file_name = file_name
        self.width = width
        self.height = height
        self.id = id
    }
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
    
    convenience init(image_id: Int, id: Int, number_of_keypoints: Int?) {
        self.init()
        
        self.image_id = image_id
        self.id = id
        
        if let number_of_keypoints = number_of_keypoints {
            keypoints = Array<Int>(repeating: 0, count: number_of_keypoints*3)
        }
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
//        init() {
//            supercategory = "bust"
//            name = "body"
//            id = 1
////            keypoints = ["index", "index DIP", "index PIP", "index MP"/*, "middle", "ring", "baby", "thumb"*/]
//            keypoints = ["head", "nose", "Rshoulder", "Lshoulder"]
//            skeleton = [[1,2], [2,3], [2,4]]
//        }
    
    init(supercategory: String, skeleton: [[Int]], id: Int, keypoints: [String], name: String) {
        self.supercategory = supercategory
        self.skeleton = skeleton
        self.id = id
        self.keypoints = keypoints
        self.name = name
    }
}
