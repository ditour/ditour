//
//  ILobbyXMLAttributeParser.h
//  iLobby
//
//  Created by Pelaia II, Tom on 10/29/13.
//  Copyright (c) 2013 UT-Battelle ORNL. All rights reserved.
//

#import <Foundation/Foundation.h>


// convenience class to fetch elements and their attributes from XML
@interface ILobbyXMLAttributeParser : NSObject <NSXMLParserDelegate>
/// \brief Fetch elements and their attributes from the given XML. If the XML contains multiple elements of the same tag then the last such element overrites all other data.
/// \param xml String of XML to parse.
/// \param errorPtr Pointer to any error on return or pass nil to ignore it.
/// \returns Dictionary of attributes and values in turn keyed by the element tag (e.g. attributeValue = result[tag][attribute]) with all keys in upper case.
+ (NSDictionary *)fetchElementsAttributesForXML:(NSString *)xml error:(NSError * __autoreleasing *)errorPtr;
@end
