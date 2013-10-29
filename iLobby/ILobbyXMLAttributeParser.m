//
//  ILobbyXMLAttributeParser.m
//  iLobby
//
//  Created by Pelaia II, Tom on 10/29/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import "ILobbyXMLAttributeParser.h"


@interface ILobbyXMLAttributeParser ()
@property(nonatomic) NSMutableDictionary *attributeCache;
@end


@implementation ILobbyXMLAttributeParser

- (id)init {
    self = [super init];
    if (self) {
        self.attributeCache = [NSMutableDictionary new];
    }
    return self;
}


+ (NSDictionary *)fetchElementsAttributesForXML:(NSString *)xml error:(NSError * __autoreleasing *)errorPtr {
	ILobbyXMLAttributeParser *attributeParser = [self new];

	NSData *xmlData = [xml dataUsingEncoding:NSUTF8StringEncoding];
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:xmlData];
	xmlParser.delegate = attributeParser;

	if ( [xmlParser parse] ) {
		return [attributeParser.attributeCache copy];
	}
	else {
		if ( errorPtr ) {
			*errorPtr = xmlParser.parserError;
		}
		return nil;
	}

}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	NSMutableDictionary *upperAttributes = [NSMutableDictionary new];
	for ( NSString *key in attributeDict.allKeys ) {
		upperAttributes[key.uppercaseString] = attributeDict[key];
	}
	self.attributeCache[elementName.uppercaseString] = upperAttributes;
}

@end
