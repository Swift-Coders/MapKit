//
//  SegueHandlerType.swift
//  Maps
//
//  Created by Yariv Nissim on 11/14/15.
//  Copyright © 2015 LearnSwiftLA. All rights reserved.
//

import UIKit

public protocol SegueHandlerType {
    typealias SegueIdentifier: RawRepresentable
}

// This method only works when a SegueIdentifier enum with String values is defined
public extension SegueHandlerType where Self: UIViewController, SegueIdentifier.RawValue == String {
    
    func performSegueWithIdentifier(segueIdentifier: SegueIdentifier, sender: AnyObject?) {
        performSegueWithIdentifier(segueIdentifier.rawValue, sender: sender)
    }
    
    func segueIdentifierForSegue(segue: UIStoryboardSegue) -> SegueIdentifier {
        guard let identifier = segue.identifier,
            segueIdentifier = SegueIdentifier(rawValue: identifier) else {
                fatalError("Couldn't handle segue identifier \(segue.identifier) for view controller of type \(self.dynamicType).")
        }
        return segueIdentifier
    }
}
