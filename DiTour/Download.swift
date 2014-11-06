//
//  Download.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 11/6/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation


/* Represents a file on a remote server */
class RemoteFile : NSObject, ILobbyRemoteDirectoryItem {
	/* remote location of the file */
	var location: NSURL

	/* indicates whether this item is a directory (always returns false) */
	var isDirectory: Bool { return false }

	/* information about the file from the remote directory */
	var info : String


	/* description of this remote file including the location and info */
	override var description : String {
		return "location: \(self.location.absoluteString), info: \(self.info)"
	}


	init(location: NSURL, info: String) {
		self.location = location
		self.info = info
	}
}