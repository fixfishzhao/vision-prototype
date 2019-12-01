//
//  articles.swift
//  Vision Project V2 Prototype
//
//  Created by Zheng on 29/11/19.
//  Copyright © 2019 VisaulCamp. All rights reserved.
//

import Foundation

class Article {
    
    let articleThumbnail : String
    let articleTitle : String
    let articleURL: String
    
    init(thumbnail: String, title: String, url: String) {
        articleThumbnail = thumbnail
        articleTitle = title
        articleURL = url
    }

}
