//
//  utils.swift
//  CoreOrate
//
//  Created by LegitMichel777 on 2021/2/6.
//

import Foundation
func next2Pow(x: Int) -> Int {
    if ((x&(-x))==x) {
        return x
    }
    var i=1
    var xc=x
    while (i<=32) {
        xc|=(xc>>i)
        i<<=1
    }
    return xc+1 
}
