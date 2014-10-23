//
//  Presentation.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 10/22/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation
import QuartzCore


struct TransitionSource {
	var duration : CFTimeInterval = 0.0
	var type : String?
	var subType : String?


	init( config : [String:NSObject] ) {
		if let duration = config["duration"] as? Double {
			self.duration = duration
		}

		self.type = config["type"] as? String
		self.subType = config["subtype"] as? String
	}


	func generate() -> CATransition {
		let transition = CATransition()
		transition.type = self.type
		transition.subtype = self.subType
		transition.duration = self.duration
		return transition;
	}
}


