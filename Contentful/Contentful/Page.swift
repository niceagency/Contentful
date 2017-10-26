//
//  Page.swift
//  DeviceManagement
//
//  Created by Sam Woolf on 23/10/2017.
//  Copyright © 2017 Nice Agency. All rights reserved.
//

import Foundation

public struct Page {
    
    let itemsPerPage: Int
    let currentPage: Int
    let totalItemsAvailable: Int?
    
    func getNextPage() -> Page? {
        
        if isNextPageAvailable() {
            return Page(itemsPerPage: self.itemsPerPage, currentPage: currentPage + 1, totalItemsAvailable: totalItemsAvailable)
        }
        return nil
    }
    
    func getPrevPage() -> Page? {
        
        if isPrevPageAvailable() {
            return Page(itemsPerPage: self.itemsPerPage, currentPage: currentPage - 1, totalItemsAvailable: totalItemsAvailable)
        }
        return nil
    }
    
   static func getFirstPage(itemsPerPage: Int) -> Page {
        return Page(itemsPerPage: itemsPerPage, currentPage: 0, totalItemsAvailable: nil)
    }
    
    func isNextPageAvailable() -> Bool {
        guard let total  = totalItemsAvailable else { return false }
        
        if (currentPage + 1) * itemsPerPage < total {
            return true
        }
        return false
    }
    
    func isPrevPageAvailable() -> Bool {
        
        if (currentPage - 1) >= 0 {
            return true
        }
        return false
    }
}
