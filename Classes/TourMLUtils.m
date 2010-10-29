#import "TourMLUtils.h"

@interface TourMLUtils (PrivateMethods)

+ (xmlXPathObjectPtr)executeXPathQuery:(NSString *)xpath againstDocument:(xmlDocPtr)document;

@end


@implementation TourMLUtils

+ (xmlNodePtr)getTitleInDocument:(xmlDocPtr)document
{
	xmlXPathObjectPtr xpathObj = [TourMLUtils executeXPathQuery:@"/TourML:Tour/TourML:Title" againstDocument:document];
	if (xpathObj == NULL) {
		return NULL;
	}
	xmlNodePtr title = xpathObj->nodesetval->nodeTab[0];
	xmlXPathFreeObject(xpathObj);
	return title;
}

+ (xmlNodePtr)getImageInDocument:(xmlDocPtr)document
{
	xmlXPathObjectPtr xpathObj = [TourMLUtils executeXPathQuery:@"/TourML:Tour/TourML:Image" againstDocument:document];
	if (xpathObj == NULL) {
		return NULL;
	}
	xmlNodePtr image = xpathObj->nodesetval->nodeTab[0];
	xmlXPathFreeObject(xpathObj);
	return image;
}

+ (xmlNodePtr)getSponsorImageInDocument:(xmlDocPtr)document
{
	xmlXPathObjectPtr xpathObj = [TourMLUtils executeXPathQuery:@"/TourML:Tour/TourML:SponsorImage" againstDocument:document];
	if (xpathObj == NULL) {
		return NULL;
	}
	xmlNodePtr image = xpathObj->nodesetval->nodeTab[0];
	xmlXPathFreeObject(xpathObj);
	return image;
}

+ (xmlNodePtr)getLocalizationInDocument:(xmlDocPtr)document withName:(NSString *)name
{
	xmlXPathObjectPtr xpathObj = [TourMLUtils executeXPathQuery:[NSString stringWithFormat:@"/TourML:Tour/TourML:%@", name] againstDocument:document];
	if (xpathObj == NULL) {
		return NULL;
	}
	xmlNodePtr stop = xpathObj->nodesetval->nodeTab[0];
	xmlXPathFreeObject(xpathObj);
	return stop;
}

+ (xmlNodePtr)getStopInDocument:(xmlDocPtr)document withCode:(NSString *)code
{
	xmlXPathObjectPtr xpathObj = [TourMLUtils executeXPathQuery:[NSString stringWithFormat:@"/TourML:Tour/*[@code='%@']", code] againstDocument:document];
	if (xpathObj == NULL) {
		return NULL;
	}
	xmlNodePtr stop = xpathObj->nodesetval->nodeTab[0];
	xmlXPathFreeObject(xpathObj);
	return stop;
}

+ (xmlNodePtr)getStopInDocument:(xmlDocPtr)document withIdentifier:(NSString *)ident
{
	xmlXPathObjectPtr xpathObj = [TourMLUtils executeXPathQuery:[NSString stringWithFormat:@"/TourML:Tour/*[@id='%@']", ident] againstDocument:document];
	if (xpathObj == NULL) {
		return NULL;
	}
	xmlNodePtr stop = xpathObj->nodesetval->nodeTab[0];
	xmlXPathFreeObject(xpathObj);
	return stop;
}

+ (xmlNodeSetPtr)getAllStopsInDocument:(xmlDocPtr)document
{
	xmlXPathObjectPtr xpathObj = [TourMLUtils executeXPathQuery:@"/TourML:Tour/*" againstDocument:document];
	if (xpathObj == NULL) {
		return NULL;
	}
	xmlNodeSetPtr stops = xpathObj->nodesetval;
	xmlXPathFreeNodeSetList(xpathObj);
	return stops;
}

+ (xmlNodeSetPtr)getAllSourceNodesInDocument:(xmlDocPtr)document
{
	xmlXPathObjectPtr xpathObj = [TourMLUtils executeXPathQuery:@"//TourML:Source" againstDocument:document];
	if (xpathObj == NULL) {
		return NULL;
	}
	xmlNodeSetPtr nodes = xpathObj->nodesetval;
	xmlXPathFreeNodeSetList(xpathObj);
	return nodes;
}

+ (xmlNodeSetPtr)getAllHeaderNodesInDocument:(xmlDocPtr)document
{
	xmlXPathObjectPtr xpathObj = [TourMLUtils executeXPathQuery:@"//TourML:Param[starts-with(@key, 'header-image')]" againstDocument:document];
	if (xpathObj == NULL) {
		return NULL;
	}
	xmlNodeSetPtr nodes = xpathObj->nodesetval;
	xmlXPathFreeNodeSetList(xpathObj);
	return nodes;
}

+ (xmlXPathObjectPtr)executeXPathQuery:(NSString *)xpath againstDocument:(xmlDocPtr)document
{
	xmlXPathContextPtr xpathCtx;
    xmlXPathObjectPtr xpathObj;
	xpathCtx = xmlXPathNewContext(document);
    if(xpathCtx == NULL) {
		return NULL;
    }
	xmlXPathRegisterNs(xpathCtx, (xmlChar*)TOURML_XML_PREFIX, (xmlChar*)TOURML_XMLNS);
	xmlChar *xpathExpr = (xmlChar*)[xpath UTF8String];
	xpathObj = xmlXPathEvalExpression(xpathExpr, xpathCtx);
	if (xpathObj == NULL) {
		xmlXPathFreeContext(xpathCtx);
		return NULL;
	}
	if (xmlXPathNodeSetIsEmpty(xpathObj->nodesetval)) {
		xmlXPathFreeContext(xpathCtx);
		xmlXPathFreeObject(xpathObj);
		return NULL;
	}
	xmlXPathFreeContext(xpathCtx);
	return xpathObj;
}

@end
