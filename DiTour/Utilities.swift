//
//  Utilities.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 11/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation



/* dictionary that allows thread safe concurrent access */
class ConcurrentDictionary<KeyType:Hashable,ValueType> : NSObject, SequenceType {
	/* internal dictionary */
	var dictionary : [KeyType:ValueType]

	/* queue modfications using a barrier and allow concurrent read operations */
	let queue = dispatch_queue_create( "dictionary access", DISPATCH_QUEUE_CONCURRENT )


	/* count of key-value pairs in this dicitionary */
	var count : Int {
		return self.dictionary.count
	}


	/* initialize an empty dictionary */
	override convenience init() {
		self.init( dictionary: [KeyType:ValueType]() )
	}


	/* initialize a concurrent dictionary from a copy of a standard dictionary */
	init( dictionary: [KeyType:ValueType] ) {
		self.dictionary = dictionary
	}


	/* provide subscript accessors */
	subscript(key: KeyType) -> ValueType? {
		get {
			return self.dictionary[key]
		}

		set {
			// need to synchronize writes for consistent modifications
			dispatch_barrier_async(self.queue) { () -> Void in
				self.dictionary[key] = newValue
			}
		}
	}


	/* assign the specified value to the specified key */
	func setValue(value: ValueType, forKey key: KeyType) {
		self[key] = value
	}


	/* remove the value associated with the specified key and return its value if any */
	func removeValueForKey(key: KeyType) -> ValueType? {
		var oldValue : ValueType? = nil
		// need to synchronize removal for consistent modifications
		dispatch_barrier_sync(self.queue) { () -> Void in
			oldValue = self.dictionary.removeValueForKey(key)
		}
		return oldValue
	}


	/* Generator of key-value pairs suitable for for-in loops */
	func generate() -> Dictionary<KeyType,ValueType>.Generator {
		return self.dictionary.generate()
	}
}