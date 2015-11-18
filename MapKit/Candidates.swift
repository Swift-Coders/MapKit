//
//  Candidates.swift
//  Maps
//
//  Created by Yariv Nissim on 11/14/15.
//  Copyright © 2015 LearnSwiftLA. All rights reserved.
//

import UIKit
import MapKit

enum Party: String {
    case Democrat
    case Republican
}

struct Candidate: Hashable {
    let name: String
    let party: Party
    
    var hashValue: Int { return name.hashValue ^ party.hashValue } // Hashable
}

extension Candidate {
    var preferredColor: UIColor {
        switch party {
        case .Democrat: return .blueColor()
        case .Republican: return .redColor()
        }
    }
}

// Equatable
func ==(left: Candidate, right: Candidate) -> Bool {
    return left.name == right.name && left.party == right.party
}

let candidates = Set<Candidate>(arrayLiteral:
    // Democrats
    Candidate(name: "Bernie Sanders", party: .Democrat),
    Candidate(name: "Hillary Clinton", party: .Democrat),
    Candidate(name: "Martin O'Malley", party: .Democrat),
    // Republicans
    Candidate(name: "Jeb Bush", party: .Republican),
    Candidate(name: "Ben Carson", party: .Republican),
    Candidate(name: "Ted Cruz", party: .Republican),
    Candidate(name: "Mike Huckabee", party: .Republican),
    Candidate(name: "Donald Trump", party: .Republican),
    Candidate(name: "Mitt Romney", party: .Republican)
)

class Vote: MKPointAnnotation {
    var candidate: Candidate
    var placemark: CLPlacemark?
    var location: CLLocation {
        return CLLocation(annotation: self)
    }
    
    init(candidate: Candidate, coordinate: CLLocationCoordinate2D) {
        self.candidate = candidate
        super.init()
        self.title = candidate.name
        self.coordinate = coordinate
    }
}
