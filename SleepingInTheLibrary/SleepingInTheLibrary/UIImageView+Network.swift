//
//  UIImageView+Network.swift
//  ImageRequest
//
//  Created by Victor on 3/13/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import Foundation
import UIKit

extension UIImageView {
    
    func loadUrl(let urlString: String!) {
        let url = NSURL(string: urlString)!
        let task = NSURLSession.sharedSession().dataTaskWithURL(url) {
            (data, response, error) in
            
            if error == nil {
                let loadedImage = UIImage(data: data!)
                
                performUIUpdatesOnMain {
                    self.image = loadedImage;
                }
            }
        }
        
        task.resume();
    }
    
}