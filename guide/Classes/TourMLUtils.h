#import <Foundation/Foundation.h>

#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

#define TOURML_XMLNS		"http://www.imamuseum.org/TourML/1.0"
#define TOURML_XML_PREFIX	"TourML"

@interface TourMLUtils : NSObject {

}

// Check if an id exists in the tour document and return it
+ (xmlNodePtr)getIdInDocument:(xmlDocPtr)document;

// Check if a title exists in the tour document and return it
+ (xmlNodePtr)getTitleInDocument:(xmlDocPtr)document;

// Check if an image exists in the tour document and return it
+ (xmlNodePtr)getImageInDocument:(xmlDocPtr)document;

// Check if an sponsor image exists in the tour document and return it
+ (xmlNodePtr)getSponsorImageInDocument:(xmlDocPtr)document;

// Check if an language exists in the tour document and return it
+ (xmlNodePtr)getLanguageInDocument:(xmlDocPtr)document;

// Check if a localization exits in the tour document and return it
+ (xmlNodePtr)getLocalizationInDocument:(xmlDocPtr)document withName:(NSString *)name;

// Check if a code exists in the tour document and return the stop element
+ (xmlNodePtr)getStopInDocument:(xmlDocPtr)document withCode:(NSString *)code;

// Check if a code exists in the tour document and return the stop element
+ (xmlNodePtr)getStopInDocument:(xmlDocPtr)document withIdentifier:(NSString *)indent;

// Attempt to retrieve all stops from a TourML doc
+ (xmlNodeSetPtr)getAllStopsInDocument:(xmlDocPtr)document;

// Attempt to retrieve all <Source> nodes from a a TourML doc
+ (xmlNodeSetPtr)getAllSourceNodesInDocument:(xmlDocPtr)document;

// Attempt to retrieve all <Param> nodes from a a TourML doc that describe a header image
+ (xmlNodeSetPtr)getAllHeaderNodesInDocument:(xmlDocPtr)document;

@end
