//
//  ToursXMLParser.h
//  Test
//
//  Created by Robert Brecher on 9/16/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <libxml/xmlreader.h>

@interface ToursXMLParser : NSObject {
	
}

+ (NSArray *)parseToursXML:(NSData *)xmlData;

@end
