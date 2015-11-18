//
//  CandidatesViewController.swift
//  Maps
//
//  Created by Yariv Nissim on 11/14/15.
//  Copyright © 2015 LearnSwiftLA. All rights reserved.
//

import UIKit

protocol CandidateContainer {
    var candidate: Candidate? { get }
}

class CandidatesViewController: UITableViewController, CandidateContainer {
    
    var candidate: Candidate? {
        guard let indexPath = tableView.indexPathForSelectedRow else { return nil }
        return candidatesByParty[indexPath.section][indexPath.row]
    }
    
    let candidatesByParty = [
        candidates.filter{ $0.party == Party.Democrat},
        candidates.filter{ $0.party == Party.Republican }
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        preferredContentSize = tableView.contentSize
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return candidatesByParty.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return candidatesByParty[section].count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Candidate", forIndexPath: indexPath)
        
        let candidate = candidatesByParty[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = candidate.name
        cell.textLabel?.textColor = candidate.preferredColor
        
        return cell
    }
    
    private let parties = [Party.Democrat, .Republican]
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return parties[section].rawValue
    }
}