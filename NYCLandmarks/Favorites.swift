//
//  Favorites.swift
//  NYCLandmarks
//
//  Created by John Robokos on 9/21/18.
//  Copyright © 2018 Robokos, John. All rights reserved.
//

import Foundation

class Favorites {
    let KEY = "favorites"
    static let `default` = Favorites()
    
    func allFavorites() -> [Int] {
        if let f = UserDefaults.standard.array(forKey: KEY) as? [Int] {
            return f
        }
        return []
    }
    
    func isFavorite(_ id: Int) -> Bool {
            
        if let favorites = UserDefaults.standard.array(forKey: KEY) as? [Int],
            favorites.contains(where: { $0 == id}) {
            return true
        }
        return false        
    }
    
    func unsaveFavorite(_ id: Int){
        
        if let favorites = UserDefaults.standard.array(forKey: KEY) as? [Int],
            favorites.contains(where: { $0 == id }) {
            let tmp = favorites.filter{ $0 != id}
            UserDefaults.standard.set(tmp, forKey: KEY)
        }
    }
    
    func saveFavorite(_ id: Int){
        if UserDefaults.standard.array(forKey: KEY) == nil  {
            UserDefaults.standard.set([id], forKey: KEY)
        }
        
        if var favorites = UserDefaults.standard.array(forKey: KEY) as? [Int],
            !favorites.contains{ $0 == id} {
            favorites.append(id)
            UserDefaults.standard.set(favorites, forKey: KEY)
        }
    }
}
