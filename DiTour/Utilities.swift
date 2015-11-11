//
//  Utilities.swift
//  DiTour
//
//  Created by Pelaia II, Tom on 11/10/14.
//  Copyright (c) 2014 UT-Battelle ORNL. All rights reserved.
//

import Foundation


/* convenience extensions to provide required NSString properties and methods */
extension String {
	var pathExtension : String {
		return (self as NSString).pathExtension
	}

	var lastPathComponent : String {
		return (self as NSString).lastPathComponent
	}

	var stringByDeletingPathExtension : String {
		return (self as NSString).stringByDeletingPathExtension
	}

	var stringByDeletingLastPathComponent : String {
		return (self as NSString).stringByDeletingLastPathComponent
	}

	func stringByAppendingPathComponent(component: String) -> String {
		return (self as NSString).stringByAppendingPathComponent(component)
	}
}



/* dictionary that allows thread safe concurrent access */
final class ConcurrentDictionary<KeyType:Hashable,ValueType> : NSObject, SequenceType, DictionaryLiteralConvertible {
	/* internal dictionary */
	private var dictionary : [KeyType:ValueType]

	/* queue modfications using a barrier and allow concurrent read operations */
	private let queue = dispatch_queue_create( "dictionary access", DISPATCH_QUEUE_CONCURRENT )


	/* count of key-value pairs in this dicitionary */
	var count : Int {
		var count = 0
		dispatch_sync(self.queue) { () -> Void in
			count = self.dictionary.count
		}
		return count
	}


	/* initialize an empty dictionary */
	override convenience init() {
		self.init( dictionary: [KeyType:ValueType]() )
	}


	/* allow a concurrent dictionary to be initialized using a dictionary literal of form: [key1:value1, key2:value2, ...] */
	convenience required init(dictionaryLiteral elements: (KeyType, ValueType)...) {
		var dictionary = Dictionary<KeyType,ValueType>()

		for (key,value) in elements {
			dictionary[key] = value
		}

		self.init(dictionary: dictionary)
	}


	/* initialize a concurrent dictionary from a copy of a standard dictionary */
	init( dictionary: [KeyType:ValueType] ) {
		self.dictionary = dictionary
	}


	/* provide subscript accessors */
	subscript(key: KeyType) -> ValueType? {
		get {
			var value : ValueType?
			dispatch_sync(self.queue) { () -> Void in
				value = self.dictionary[key]
			}
			return value
		}

		set {
			setValue(newValue, forKey: key)
		}
	}


	/* assign the specified value to the specified key */
	func setValue(value: ValueType?, forKey key: KeyType) {
		// need to synchronize writes for consistent modifications
		dispatch_barrier_async(self.queue) { () -> Void in
			self.dictionary[key] = value
		}
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
		var generator : Dictionary<KeyType,ValueType>.Generator!
		dispatch_sync(self.queue) { () -> Void in
			generator = self.dictionary.generate()
		}
		return generator
	}
}